"""Validation suite for the threatmodel compiler.

Runs entirely offline (no Chronicle/Splunk SaaS dependency). Exercises:

* IR loading + access-tree flattening.
* All four emitters produce non-empty content for the seeded reference threats.
* BigQuery SQL parses through ``sqlglot`` if installed (skipped otherwise so
  the suite is friendly to environments without optional deps).
* KQL queries parse via a lightweight syntax sanity check.
* YARA-L rules contain the required structural sections.
* MITRE technique IDs resolve to Cloud-matrix tactics.
* ATT&CK Navigator JSON is well-formed and references known techniques.
* The BigQuery scheduled-query Terraform module is syntactically valid HCL
  (``terraform validate`` is invoked when the binary is present).
"""
from __future__ import annotations

import importlib.util
import json
import re
import shutil
import subprocess
from pathlib import Path

import pytest

from threatmodel_compiler import loader, mitre, permission_map as pm
from threatmodel_compiler.emitters import attack_navigator, bigquery_sql, chronicle_yaral, sentinel_kql, splunk_spl


REPO_ROOT = Path(__file__).resolve().parents[3]
JSON_PATH = REPO_ROOT / "threatmodel-gcp-bigquery.json"
REFERENCE_THREATS = ["Bigquery.T1", "Bigquery.T6", "Bigquery.T9"]


@pytest.fixture(scope="module")
def model() -> loader.ThreatModel:
    return loader.load(JSON_PATH)


@pytest.fixture(scope="module")
def signals() -> dict[str, pm.PermissionSignal]:
    return pm.load()


def test_ir_loads_with_expected_threats(model: loader.ThreatModel) -> None:
    assert len(model.threats) >= 30
    for tid in REFERENCE_THREATS:
        assert tid in model.threats


def test_access_tree_flattens_or_branch(model: loader.ThreatModel) -> None:
    t9 = model.threat("Bigquery.T9")
    # T9's OR includes datasets.update and the AND(jobs.create, tables.getData) branch.
    assert "bigquery.datasets.update" in t9.required_permissions
    assert "bigquery.jobs.create" in t9.required_permissions
    assert "bigquery.tables.getData" in t9.required_permissions


def test_access_tree_flattens_optional(model: loader.ThreatModel) -> None:
    t6 = model.threat("Bigquery.T6")
    # T6's storage.* perms sit inside an OPTIONAL branch and must land in optional[].
    assert "storage.objects.create" in t6.optional_permissions
    assert "storage.objects.delete" in t6.optional_permissions
    assert "bigquery.tables.export" in t6.required_permissions


def test_permission_map_covers_reference_threats(model: loader.ThreatModel,
                                                 signals: dict[str, pm.PermissionSignal]) -> None:
    for tid in REFERENCE_THREATS:
        t = model.threat(tid)
        for perm in t.required_permissions + t.optional_permissions:
            assert perm in signals, f"missing permission map entry for {perm} (threat {tid})"


def test_permission_map_method_names_well_formed(signals: dict[str, pm.PermissionSignal]) -> None:
    for perm, sig in signals.items():
        assert sig.service_name.endswith(".googleapis.com"), perm
        assert sig.log_type in {"data_access", "admin_activity", "system_event"}, perm
        assert sig.method_names, perm


@pytest.mark.parametrize("tid", REFERENCE_THREATS)
def test_bigquery_sql_emitter(model: loader.ThreatModel, signals, tid: str) -> None:
    artifact = bigquery_sql.emit(model.threat(tid), signals)
    assert artifact is not None
    assert tid in artifact.sql
    assert "AUTO-GENERATED" in artifact.sql
    assert "${audit_project}" in artifact.sql
    assert "${audit_dataset}" in artifact.sql
    assert "google_bigquery_data_transfer_config" in artifact.terraform


@pytest.mark.parametrize("tid", REFERENCE_THREATS)
def test_bigquery_sql_parses_with_sqlglot(model: loader.ThreatModel, signals, tid: str) -> None:
    if importlib.util.find_spec("sqlglot") is None:
        pytest.skip("sqlglot not installed")
    import sqlglot
    sql = bigquery_sql.emit(model.threat(tid), signals).sql
    parsed = sqlglot.parse(sql, read="bigquery")
    assert any(stmt is not None for stmt in parsed)


@pytest.mark.parametrize("tid", REFERENCE_THREATS)
def test_yaral_rule_structure(model: loader.ThreatModel, signals, tid: str) -> None:
    rule = chronicle_yaral.emit(model.threat(tid), signals)
    assert rule is not None
    for required_section in ("rule ", "meta:", "events:", "condition:"):
        assert required_section in rule, f"YARA-L rule for {tid} missing {required_section}"


@pytest.mark.parametrize("tid", REFERENCE_THREATS)
def test_splunk_spl_shape(model: loader.ThreatModel, signals, tid: str) -> None:
    spl = splunk_spl.emit(model.threat(tid), signals)
    assert spl is not None
    assert "index=gcp" in spl
    assert "data.protoPayload.serviceName=bigquery.googleapis.com" in spl


@pytest.mark.parametrize("tid", REFERENCE_THREATS)
def test_sentinel_kql_shape(model: loader.ThreatModel, signals, tid: str) -> None:
    kql = sentinel_kql.emit(model.threat(tid), signals)
    assert kql is not None
    assert "GCPAuditLogs_CL" in kql
    assert "| where" in kql


def test_kql_balanced_braces_and_parens() -> None:
    """Lightweight KQL sanity check — balanced parens, no obvious typos."""
    for path in (REPO_ROOT / "detections").glob("**/*.kql"):
        text = path.read_text(encoding="utf-8")
        assert text.count("(") == text.count(")"), path
        assert text.count("[") == text.count("]"), path


def test_mitre_resolution() -> None:
    for tactic_id in ("TA0001", "TA0010", "TA0040"):
        assert mitre.resolve(tactic_id) is not None


def test_attack_navigator_layer(model: loader.ThreatModel) -> None:
    layer_text = attack_navigator.emit(model, REFERENCE_THREATS)
    layer = json.loads(layer_text)
    assert layer["domain"] == "enterprise-attack"
    assert layer["techniques"], "navigator layer must include techniques"
    seen_ids = {tech["techniqueID"] for tech in layer["techniques"]}
    assert "T1485" in seen_ids  # Data Destruction (TA0040)
    assert "T1567.002" in seen_ids  # Exfil to Cloud Storage (TA0010)


def test_terraform_validate_when_available(tmp_path: Path) -> None:
    if shutil.which("terraform") is None:
        pytest.skip("terraform binary not on PATH")
    bigquery_sql_dir = REPO_ROOT / "detections" / "Bigquery.T1" / "bigquery_sql"
    tf_dir = bigquery_sql_dir / "terraform"
    if not tf_dir.exists():
        pytest.skip("compiler output not present; run `python -m threatmodel_compiler compile` first")
    # Mirror the relative layout the module expects (../detect_t1.sql).
    work = tmp_path / "bigquery_sql"
    (work / "terraform").mkdir(parents=True)
    for f in tf_dir.iterdir():
        (work / "terraform" / f.name).write_bytes(f.read_bytes())
    for f in bigquery_sql_dir.glob("*.sql"):
        (work / f.name).write_bytes(f.read_bytes())
    init = subprocess.run(["terraform", "init", "-backend=false", "-input=false"],
                          cwd=work / "terraform", capture_output=True, text=True)
    assert init.returncode == 0, init.stderr
    validate = subprocess.run(["terraform", "validate"], cwd=work / "terraform",
                              capture_output=True, text=True)
    assert validate.returncode == 0, validate.stderr


def test_no_unsafe_admin_query_patterns() -> None:
    """Compiled SQL must not include destructive/admin operations."""
    bad = re.compile(r"\b(DROP|DELETE\s+FROM|TRUNCATE|UPDATE\s+\w+\s+SET|GRANT|REVOKE)\b", re.IGNORECASE)
    for path in (REPO_ROOT / "detections").glob("**/*.sql"):
        text = path.read_text(encoding="utf-8")
        # Allow DELETE inside string literals (e.g. methodName "...DeleteTable") via simple comment-strip:
        stripped = re.sub(r"--.*", "", text)
        stripped = re.sub(r"'(?:[^'\\]|\\.)*'", "''", stripped)
        assert not bad.search(stripped), f"{path} contains a non-read-only SQL statement"

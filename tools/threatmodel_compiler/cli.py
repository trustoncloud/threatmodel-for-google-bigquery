"""CLI entrypoint: ``python -m threatmodel_compiler compile [...]``."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import loader
from . import permission_map as pm
from . import mitre
from .emitters import attack_navigator, bigquery_sql, chronicle_yaral, sentinel_kql, splunk_spl
from . import coverage


_DEFAULT_THREATS = ["Bigquery.T1", "Bigquery.T6", "Bigquery.T9"]


def _normalize(threat_ids: list[str]) -> list[str]:
    return [t if "." in t else f"Bigquery.{t}" for t in threat_ids]


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def _emit_per_threat(threat, signals, out_root: Path) -> dict[str, list[str]]:
    artifacts: dict[str, list[str]] = {"emitted": [], "skipped": []}
    base = out_root / threat.id

    bq = bigquery_sql.emit(threat, signals)
    if bq is not None:
        snake = threat.short_id.lower()
        _write(base / "bigquery_sql" / f"detect_{snake}.sql", bq.sql)
        _write(base / "bigquery_sql" / "terraform" / "main.tf", bq.terraform)
        artifacts["emitted"].append("bigquery_sql")
    else:
        artifacts["skipped"].append("bigquery_sql")

    yaral = chronicle_yaral.emit(threat, signals)
    if yaral is not None:
        snake = threat.short_id.lower()
        _write(base / "chronicle_yaral" / f"detect_{snake}.yaral", yaral)
        artifacts["emitted"].append("chronicle_yaral")
    else:
        artifacts["skipped"].append("chronicle_yaral")

    spl = splunk_spl.emit(threat, signals)
    if spl is not None:
        snake = threat.short_id.lower()
        _write(base / "splunk_spl" / f"detect_{snake}.spl", spl)
        artifacts["emitted"].append("splunk_spl")
    else:
        artifacts["skipped"].append("splunk_spl")

    kql = sentinel_kql.emit(threat, signals)
    if kql is not None:
        snake = threat.short_id.lower()
        _write(base / "sentinel_kql" / f"detect_{snake}.kql", kql)
        artifacts["emitted"].append("sentinel_kql")
    else:
        artifacts["skipped"].append("sentinel_kql")

    tactic = mitre.resolve(threat.mitre_tactic)
    metadata = {
        "threat_id": threat.id,
        "name": threat.name,
        "feature_class": threat.feature_class,
        "hlgoal": threat.hlgoal,
        "mitre_tactic": threat.mitre_tactic,
        "mitre_tactic_name": tactic.name if tactic else None,
        "mitre_techniques": [{"id": tid, "name": tname} for tid, tname in (tactic.techniques if tactic else ())],
        "atlas_techniques": [{"id": tid, "name": tname}
                             for tid, tname in mitre.atlas_techniques_for_hlgoal(threat.hlgoal)],
        "cvss_severity": threat.cvss_severity,
        "cvss_score": threat.cvss_score,
        "required_permissions": threat.required_permissions,
        "optional_permissions": threat.optional_permissions,
        "emitted_artifacts": artifacts["emitted"],
        "source_of_truth": "threatmodel-gcp-bigquery.json",
    }
    _write(base / "metadata.json", json.dumps(metadata, indent=2) + "\n")
    return artifacts


def _cmd_compile(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve()
    json_path = repo_root / "threatmodel-gcp-bigquery.json"
    if not json_path.exists():
        print(f"error: {json_path} not found", file=sys.stderr)
        return 2

    model = loader.load(json_path)
    signals = pm.load()

    threat_ids = _normalize(args.threats or _DEFAULT_THREATS)
    out_root = repo_root / "detections"
    out_root.mkdir(exist_ok=True)

    summary: dict[str, dict[str, list[str]]] = {}
    for tid in threat_ids:
        try:
            t = model.threat(tid)
        except KeyError:
            print(f"warn: skipping unknown threat {tid}", file=sys.stderr)
            continue
        unmapped = [p for p in t.required_permissions + t.optional_permissions if p not in signals]
        if unmapped:
            print(
                f"error: threat {tid} references unmapped permissions: {unmapped}\n"
                f"       add them to tools/threatmodel_compiler/permission_map.yaml",
                file=sys.stderr,
            )
            return 3
        summary[tid] = _emit_per_threat(t, signals, out_root)

    nav_layer = attack_navigator.emit(model, threat_ids)
    _write(out_root / "attack_navigator" / "bigquery_threat_coverage.json", nav_layer)

    coverage_md = coverage.render(model, repo_root, out_root, threat_ids)
    _write(out_root / "README.md", coverage_md)

    print(json.dumps({"compiled": list(summary.keys()), "details": summary}, indent=2))
    return 0


def _cmd_list_threats(args: argparse.Namespace) -> int:
    model = loader.load(Path(args.repo_root).resolve() / "threatmodel-gcp-bigquery.json")
    for tid in sorted(model.threats.keys(), key=lambda x: int(x.split("T")[-1])):
        t = model.threats[tid]
        print(f"{tid:14s} {t.hlgoal:18s} {t.mitre_tactic:8s} {t.cvss_severity:8s} {t.name}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="threatmodel_compiler")
    parser.add_argument("--repo-root", default=".", help="Repository root containing threatmodel-gcp-bigquery.json")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_compile = sub.add_parser("compile", help="Emit detections for selected threats")
    p_compile.add_argument("--threats", nargs="*", help="Threat IDs (e.g. T1 T6 Bigquery.T9). Default: T1 T6 T9")
    p_compile.set_defaults(func=_cmd_compile)

    p_list = sub.add_parser("list-threats", help="List all threats in the IR")
    p_list.set_defaults(func=_cmd_list_threats)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())

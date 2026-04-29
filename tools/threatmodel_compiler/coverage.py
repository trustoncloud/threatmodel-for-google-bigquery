"""Build the prevent / detect / respond coverage matrix as Markdown."""
from __future__ import annotations

from pathlib import Path

from .loader import ThreatModel


def _wiz_controls(repo_root: Path) -> set[str]:
    controls_dir = repo_root / "wiz_custom_rules" / "controls"
    if not controls_dir.exists():
        return set()
    return {p.name for p in controls_dir.iterdir() if p.is_dir()}


def _gcp_org_constraints_present(repo_root: Path) -> bool:
    return (repo_root / "gcp_custom_org_constraints" / "customconstraints-gcp-bigquery.yaml").exists()


def _detect_artifacts(detections_dir: Path, threat_id: str) -> dict[str, bool]:
    base = detections_dir / threat_id
    return {
        "bigquery_sql": (base / "bigquery_sql").is_dir(),
        "chronicle": (base / "chronicle_yaral").is_dir(),
        "splunk": (base / "splunk_spl").is_dir(),
        "sentinel": (base / "sentinel_kql").is_dir(),
    }


def render(model: ThreatModel, repo_root: Path, detections_dir: Path, compiled_threats: list[str]) -> str:
    wiz_present = _wiz_controls(repo_root)
    gcp_present = _gcp_org_constraints_present(repo_root)

    # threats mitigated by at least one Detect-class control (existing repo)
    detect_controls = {cid for cid, c in model.controls.items() if c.nist_csf == "Detect"}
    threats_with_existing_detect: set[str] = set()
    for cid in detect_controls:
        threats_with_existing_detect.update(model.controls[cid].mitigates)

    # threats mitigated by at least one Protect-class control (existing repo)
    protect_controls = {cid for cid, c in model.controls.items() if c.nist_csf == "Protect"}
    threats_with_protect: set[str] = set()
    for cid in protect_controls:
        threats_with_protect.update(model.controls[cid].mitigates)

    lines: list[str] = []
    lines.append("# BigQuery Threat Coverage Matrix")
    lines.append("")
    lines.append("Auto-generated from `threatmodel-gcp-bigquery.json` and the artifacts in this directory.")
    lines.append("")
    lines.append("## Repo-level posture")
    lines.append("")
    lines.append(f"- Wiz custom controls present: **{len(wiz_present)}**")
    lines.append(f"- GCP custom org constraints present: **{'yes' if gcp_present else 'no'}**")
    lines.append(f"- Compiler-emitted detections (this PR): **{len(compiled_threats)} threats**")
    lines.append("")
    lines.append("## Per-threat coverage")
    lines.append("")
    lines.append("| Threat | Name | Tactic | Severity | Prevent (existing) | Detect (existing) | Detect (compiled) |")
    lines.append("|---|---|---|---|---|---|---|")

    threat_order = sorted(model.threats.values(), key=lambda t: int(t.id.split("T")[-1]))
    for t in threat_order:
        compiled = t.id in compiled_threats
        compiled_cells: list[str] = []
        if compiled:
            arts = _detect_artifacts(detections_dir, t.id)
            for k, v in arts.items():
                compiled_cells.append(f"{'+' if v else '-'}{k}")
        compiled_cell = ", ".join(compiled_cells) if compiled else "—"
        prevent_cell = "yes" if t.id in threats_with_protect else "—"
        existing_detect_cell = "yes (config)" if t.id in threats_with_existing_detect else "—"
        lines.append(
            f"| {t.id} | {t.name[:80]}{'…' if len(t.name) > 80 else ''} | "
            f"{t.mitre_tactic or '—'} | {t.cvss_severity or '—'} | "
            f"{prevent_cell} | {existing_detect_cell} | {compiled_cell} |"
        )

    lines.append("")
    lines.append("## Notes on existing 'Detect' controls")
    lines.append("")
    lines.append(
        "The repo's existing NIST CSF `Detect` controls are implemented as Rego config-posture "
        "checks (Wiz custom rules). These verify *configuration drift* and *policy violations*, "
        "not *behavioral signals from audit logs*. The compiler's `Detect (compiled)` column "
        "covers behavioral detection content (BigQuery SQL, Chronicle YARA-L, Splunk SPL, "
        "Sentinel KQL) generated from the same source-of-truth JSON."
    )
    lines.append("")
    return "\n".join(lines) + "\n"

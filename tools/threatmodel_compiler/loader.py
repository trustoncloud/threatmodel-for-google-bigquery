"""Load threatmodel-gcp-bigquery.json and normalize it into the compiler IR."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class Threat:
    id: str
    feature_class: str
    name: str
    description: str
    hlgoal: str
    mitre_tactic: str
    cvss_severity: str
    cvss_score: float
    required_permissions: list[str]
    optional_permissions: list[str]
    raw_access: dict[str, Any] | str

    @property
    def short_id(self) -> str:
        return self.id.split(".", 1)[-1]


@dataclass
class Control:
    id: str
    nist_csf: str
    coso: str
    description: str
    mitigates: list[str] = field(default_factory=list)


@dataclass
class ThreatModel:
    metadata: dict[str, Any]
    feature_classes: dict[str, dict[str, Any]]
    threats: dict[str, Threat]
    controls: dict[str, Control]

    def threat(self, threat_id: str) -> Threat:
        if threat_id in self.threats:
            return self.threats[threat_id]
        canonical = threat_id if "." in threat_id else f"Bigquery.{threat_id}"
        if canonical not in self.threats:
            raise KeyError(f"Unknown threat {threat_id!r}")
        return self.threats[canonical]


def _flatten_access(node: Any, required: list[str], optional: list[str], in_optional: bool = False) -> None:
    """Flatten the AND/OR/OPTIONAL boolean tree into required/optional permission lists.

    Approximation for detection-engineering: required = perms that must appear; optional =
    perms that strengthen the signal but are not strictly necessary. OR branches are folded
    into required (any of them present is a match candidate).
    """
    if isinstance(node, str):
        target = optional if in_optional else required
        if node not in target:
            target.append(node)
        return
    if not isinstance(node, dict):
        return
    if "OPTIONAL" in node:
        _flatten_access(node["OPTIONAL"], required, optional, in_optional=True)
        return
    if "AND" in node:
        for child in node["AND"]:
            _flatten_access(child, required, optional, in_optional=in_optional)
        return
    if "OR" in node:
        for child in node["OR"]:
            _flatten_access(child, required, optional, in_optional=in_optional)
        return


def load(path: str | Path) -> ThreatModel:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))

    threats: dict[str, Threat] = {}
    for tid, body in raw.get("threats", {}).items():
        if str(body.get("retired", "false")).lower() == "true":
            continue
        required: list[str] = []
        optional: list[str] = []
        _flatten_access(body.get("access", {}), required, optional)
        threats[tid] = Threat(
            id=tid,
            feature_class=body.get("feature_class", ""),
            name=body.get("name", ""),
            description=body.get("description", ""),
            hlgoal=body.get("hlgoal", ""),
            mitre_tactic=body.get("mitre_attack", ""),
            cvss_severity=body.get("cvss_severity", ""),
            cvss_score=float(body.get("cvss_score", 0.0)),
            required_permissions=required,
            optional_permissions=optional,
            raw_access=body.get("access", {}),
        )

    controls: dict[str, Control] = {}
    for cid, body in raw.get("controls", {}).items():
        if str(body.get("retired", "false")).lower() == "true":
            continue
        mitigates = [m.get("threat", "") for m in body.get("mitigate", []) if m.get("threat")]
        controls[cid] = Control(
            id=cid,
            nist_csf=body.get("nist_csf", ""),
            coso=body.get("coso", ""),
            description=body.get("description", ""),
            mitigates=mitigates,
        )

    return ThreatModel(
        metadata=raw.get("metadata", {}),
        feature_classes=raw.get("feature_classes", {}),
        threats=threats,
        controls=controls,
    )

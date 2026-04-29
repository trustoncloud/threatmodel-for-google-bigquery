"""Emit a MITRE ATT&CK Navigator JSON layer covering modeled threats."""
from __future__ import annotations

import json
from typing import Iterable

from ..loader import Threat, ThreatModel
from .. import mitre


_LAYER_VERSION = "4.5"
_NAVIGATOR_VERSION = "5.0.0"


def _technique_entries(threats: Iterable[Threat]) -> list[dict]:
    by_technique: dict[tuple[str, str], dict] = {}
    for t in threats:
        tactic = mitre.resolve(t.mitre_tactic)
        if tactic is None:
            continue
        for tid, tname in tactic.techniques:
            key = (tid, tactic.name.lower().replace(" ", "-"))
            entry = by_technique.setdefault(key, {
                "techniqueID": tid,
                "tactic": key[1],
                "score": 0,
                "comment": "",
                "color": "",
                "enabled": True,
                "metadata": [],
            })
            entry["score"] += 1
            entry["metadata"].append({"name": t.id, "value": t.name})
    return list(by_technique.values())


def emit(model: ThreatModel, threat_ids: list[str]) -> str:
    threats = [model.threat(tid) for tid in threat_ids]
    techniques = _technique_entries(threats)
    layer = {
        "name": "BigQuery Threat Model — Detection Coverage",
        "versions": {
            "attack": "15",
            "navigator": _NAVIGATOR_VERSION,
            "layer": _LAYER_VERSION,
        },
        "domain": "enterprise-attack",
        "description": (
            "Auto-generated coverage layer derived from threatmodel-gcp-bigquery.json. "
            f"{len(threats)} threats mapped to {len(techniques)} ATT&CK techniques."
        ),
        "filters": {"platforms": ["IaaS", "SaaS", "Google Workspace"]},
        "layout": {"layout": "side", "showName": True, "showID": True},
        "techniques": techniques,
        "gradient": {
            "colors": ["#ffffff", "#fcd116", "#cc2410"],
            "minValue": 0,
            "maxValue": max((t["score"] for t in techniques), default=1),
        },
        "legendItems": [
            {"label": "Score = number of modeled threats touching this technique", "color": "#fcd116"},
        ],
    }
    return json.dumps(layer, indent=2) + "\n"

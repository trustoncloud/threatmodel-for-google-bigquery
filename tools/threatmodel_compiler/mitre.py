"""MITRE ATT&CK tactic/technique resolution for BigQuery threats.

The threat model JSON only carries tactic IDs (TA00xx). For each tactic we map
candidate techniques relevant to BigQuery / cloud data platform behavior. Keep
this list narrow and defensible — overclaiming technique coverage is worse than
underclaiming. Sources: ATT&CK v15 Cloud matrix and ATLAS for ML threats.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class AttackTactic:
    id: str
    name: str
    techniques: tuple[tuple[str, str], ...]  # (id, name)


_TACTICS: dict[str, AttackTactic] = {
    "TA0001": AttackTactic("TA0001", "Initial Access", (
        ("T1078.004", "Valid Accounts: Cloud Accounts"),
        ("T1190", "Exploit Public-Facing Application"),
    )),
    "TA0006": AttackTactic("TA0006", "Credential Access", (
        ("T1552.004", "Unsecured Credentials: Private Keys"),
    )),
    "TA0007": AttackTactic("TA0007", "Discovery", (
        ("T1580", "Cloud Infrastructure Discovery"),
        ("T1087.004", "Account Discovery: Cloud Account"),
    )),
    "TA0008": AttackTactic("TA0008", "Lateral Movement", (
        ("T1550", "Use Alternate Authentication Material"),
    )),
    "TA0009": AttackTactic("TA0009", "Collection", (
        ("T1530", "Data from Cloud Storage"),
        ("T1213.003", "Data from Information Repositories: Code Repositories"),
    )),
    "TA0010": AttackTactic("TA0010", "Exfiltration", (
        ("T1567.002", "Exfiltration Over Web Service: Exfiltration to Cloud Storage"),
        ("T1537", "Transfer Data to Cloud Account"),
    )),
    "TA0040": AttackTactic("TA0040", "Impact", (
        ("T1485", "Data Destruction"),
        ("T1486", "Data Encrypted for Impact"),
        ("T1565.001", "Stored Data Manipulation"),
        ("T1531", "Account Access Removal"),
    )),
}

# Subset of ATLAS techniques for ML model attacks (BigQuery ML, Vertex AI integration).
_ATLAS_TECHNIQUES: dict[str, tuple[str, str]] = {
    "AML.T0020": ("AML.T0020", "Poison Training Data"),
    "AML.T0018": ("AML.T0018", "Backdoor ML Model"),
    "AML.T0024": ("AML.T0024", "Exfiltration via ML Inference API"),
}


def resolve(tactic_id: str) -> AttackTactic | None:
    return _TACTICS.get(tactic_id)


def known_tactics() -> set[str]:
    return set(_TACTICS.keys())


def atlas_techniques_for_hlgoal(hlgoal: str) -> tuple[tuple[str, str], ...]:
    if hlgoal == "DataManipulation":
        return (_ATLAS_TECHNIQUES["AML.T0020"], _ATLAS_TECHNIQUES["AML.T0018"])
    if hlgoal == "DataTheft":
        return (_ATLAS_TECHNIQUES["AML.T0024"],)
    return ()

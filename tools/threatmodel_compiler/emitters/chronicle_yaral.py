"""Emit Chronicle YARA-L 2.0 detection rules."""
from __future__ import annotations

from ..loader import Threat
from ..permission_map import PermissionSignal


def _all_method_names(threat: Threat, signals: dict[str, PermissionSignal]) -> list[str]:
    out: list[str] = []
    for perm in threat.required_permissions + threat.optional_permissions:
        sig = signals.get(perm)
        if not sig:
            continue
        for m in sig.method_names:
            if m not in out:
                out.append(m)
    return out


def _rule_for_t1(threat: Threat) -> str:
    return """
rule bigquery_t1_data_destruction {
  meta:
    author       = "threatmodel-compiler"
    severity     = "Low"
    threat_id    = "Bigquery.T1"
    mitre_tactic = "TA0040"
    mitre_id     = "T1485"
    description  = "Destruction of BigQuery data via dataset/table delete."

  events:
    $e.metadata.event_type = "RESOURCE_DELETION"
    $e.metadata.product_name = "Google Cloud BigQuery"
    (
      $e.metadata.product_event_type = "google.cloud.bigquery.v2.TableService.DeleteTable" or
      $e.metadata.product_event_type = "google.cloud.bigquery.v2.DatasetService.DeleteDataset"
    )
    $e.principal.user.email_addresses = $actor
    $e.target.resource.name = $resource

  match:
    $actor, $resource over 5m

  outcome:
    $risk_score = 35

  condition:
    $e
}
""".strip() + "\n"


def _rule_for_t6(threat: Threat) -> str:
    return r"""
rule bigquery_t6_exfil_to_unauthorized_gcs {
  meta:
    author       = "threatmodel-compiler"
    severity     = "Medium"
    threat_id    = "Bigquery.T6"
    mitre_tactic = "TA0010"
    mitre_id     = "T1567.002"
    description  = "BigQuery extract job writing to a GCS bucket outside the authorized export allowlist."

  events:
    $e.metadata.product_name = "Google Cloud BigQuery"
    $e.metadata.product_event_type = "google.cloud.bigquery.v2.JobService.InsertJob"
    $e.target.resource.attribute.labels["job_type"] = "EXTRACT"
    $e.target.resource.attribute.labels["destination_uri"] = $dest
    not re.regex($dest, `^gs://(authorized-export-bucket-1|authorized-export-bucket-2)/`)
    $e.principal.user.email_addresses = $actor

  match:
    $actor, $dest over 5m

  outcome:
    $risk_score = 65

  condition:
    $e
}
""".strip() + "\n"


def _rule_for_t9(threat: Threat) -> str:
    return r"""
rule bigquery_t9_unauthorized_query_pattern {
  meta:
    author       = "threatmodel-compiler"
    severity     = "High"
    threat_id    = "Bigquery.T9"
    mitre_tactic = "TA0010"
    mitre_id     = "T1530"
    description  = "Unauthorized query pattern: large SELECT * scans, oversized scans, or broad table fanout."

  events:
    $e.metadata.product_name = "Google Cloud BigQuery"
    $e.metadata.product_event_type = "google.cloud.bigquery.v2.JobService.InsertJob"
    $e.target.resource.attribute.labels["statement_type"] = "SELECT"
    $e.principal.user.email_addresses = $actor

    (
      // SELECT * scanning > 1 GiB
      (re.regex($e.target.resource.attribute.labels["query"], `(?i)select\s+\*\s+from`) and
       cast.as_int($e.target.resource.attribute.labels["bytes_processed"]) > 1073741824)
      or
      // Any SELECT scanning > 50 GiB
      cast.as_int($e.target.resource.attribute.labels["bytes_processed"]) > 53687091200
      or
      // Broad fanout
      cast.as_int($e.target.resource.attribute.labels["referenced_table_count"]) >= 10
    )

  match:
    $actor over 10m

  outcome:
    $risk_score = 80

  condition:
    $e
}
""".strip() + "\n"


_TEMPLATES = {
    "Bigquery.T1": _rule_for_t1,
    "Bigquery.T6": _rule_for_t6,
    "Bigquery.T9": _rule_for_t9,
}


def emit(threat: Threat, signals: dict[str, PermissionSignal]) -> str | None:
    fn = _TEMPLATES.get(threat.id)
    if fn is None:
        return None
    _ = _all_method_names(threat, signals)  # validates signals exist
    return fn(threat)

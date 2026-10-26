package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Universal safety baselines for declared jobs.
require_query_byte_limit := true

require_strict_load_schema := true

# --- Logic ---
# Finding: query job without a byte limit (unbounded cost/DoS risk).
WizPolicy[result] {
    require_query_byte_limit
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    to_number(object.get(q, "maximum_bytes_billed", 0)) == 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.maximum_bytes_billed", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "query jobs must set maximum_bytes_billed",
        "keyActualValue": "maximum_bytes_billed is not set (unlimited)",
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: load job silently dropping unknown values.
WizPolicy[result] {
    require_strict_load_schema
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    load := terraLib.getValueArrayOrObject(job.load)
    load.ignore_unknown_values == true

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].load.ignore_unknown_values", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "load jobs must not set ignore_unknown_values (strict schema)",
        "keyActualValue": "ignore_unknown_values is true",
        "resourceTags": object.get(job, "labels", {}),
    }
}

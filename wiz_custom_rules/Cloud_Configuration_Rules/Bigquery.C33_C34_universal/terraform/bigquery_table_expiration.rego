package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal data retention baseline: every table must set an expiration time
# (epoch milliseconds). Absence means infinite retention.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    to_number(object.get(tbl, "expiration_time", 0)) == 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].expiration_time", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "expiration_time must be set (no infinite retention)",
        "keyActualValue": "expiration_time is not set",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

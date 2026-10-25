package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Authorized write modes for declared query jobs. WRITE_TRUNCATE is
# intentionally excluded (destructive). Absent = WRITE_EMPTY (API default).
authorized_write_dispositions := {
    "WRITE_APPEND",
    "WRITE_EMPTY"
}

# Schema update options must stay empty (no schema drift from jobs).
allow_schema_updates := false

# --- Logic ---
# Finding: query job using a destructive or unauthorized write mode.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    disp := object.get(q, "write_disposition", "WRITE_EMPTY")
    not authorized_write_dispositions[disp]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.write_disposition", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("write_disposition must be one of: %v", [authorized_write_dispositions]),
        "keyActualValue": sprintf("write_disposition is '%v'", [disp]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: query job requesting schema updates.
WizPolicy[result] {
    allow_schema_updates == false
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    opts := object.get(q, "schema_update_options", [])
    count(opts) > 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.schema_update_options", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "schema_update_options must be empty",
        "keyActualValue": sprintf("schema_update_options is %v", [opts]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

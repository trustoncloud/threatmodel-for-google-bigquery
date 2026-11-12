package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Authorized write modes for declared query jobs. WRITE_TRUNCATE is
# intentionally excluded (destructive). Absent = WRITE_EMPTY (API default).
# The rule reads the job's write mode, create mode and schema options only. The query
# text is not read, so DROP, DELETE and TRUNCATE statements are not detected.
authorized_write_dispositions := {
    "WRITE_APPEND",
    "WRITE_EMPTY"
}

# Authorized create modes for a declared query job that writes to a
# destination table. Absent = CREATE_IF_NEEDED (API default). Remove
# CREATE_IF_NEEDED to require that the destination table already exists.
authorized_create_dispositions := {
    "CREATE_IF_NEEDED",
    "CREATE_NEVER"
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
        "keyExpectedValue": sprintf("write_disposition must be one of: %v (the query text is not read, so destructive statements in it are not detected)", [authorized_write_dispositions]),
        "keyActualValue": disposition_actual("write_disposition", disp),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: query job whose create mode for its destination table is not
# authorized.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    q.destination_table
    disp := object.get(q, "create_disposition", "CREATE_IF_NEEDED")
    not authorized_create_dispositions[disp]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.create_disposition", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("create_disposition must be one of: %v", [authorized_create_dispositions]),
        "keyActualValue": disposition_actual("create_disposition", disp),
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
        "keyExpectedValue": "schema_update_options must be empty (the query text is not read, so schema changes made by statements in it are not detected)",
        "keyActualValue": sprintf("schema_update_options is %v", [opts]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# A mode set from a variable or another resource is not known until apply,
# so it is never authorized.
disposition_actual(field, disp) := sprintf("%s is '%v', which is not known until apply", [field, disp]) {
    tocm_tf_unresolved(disp)
} else := sprintf("%s is '%v'", [field, disp])

# --- Matching helpers ---
# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Trusted Cloud Storage locations that may host User Defined Function code.
# "gs://bucket" approves the whole bucket; "gs://bucket/folder/" approves
# only what is inside that folder.
authorized_udf_locations := {
    "gs://my-corp-trusted-scripts",
    "gs://partner-lib-bucket/v1/"
}

# --- Helpers ---
bucket_allowed(uri) {
    tocm_gcs_allowed(uri, authorized_udf_locations)
}

# A location set from a variable or another resource is not known until
# apply, so it is never trusted.
uri_problem(uri) := sprintf("UDF source '%v' is not known until apply", [uri]) {
    tocm_tf_unresolved(uri)
} else := sprintf("UDF source '%v' is not in a trusted bucket or folder", [uri])

# --- Logic ---
# Finding: query job loading UDF code from an untrusted location.
# Inline-code UDF entries carry no resource_uri and are out of scope.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    udf := terraLib.getArray(q.user_defined_function_resources)[uidx]
    uri := udf.resource_uri
    not bucket_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.user_defined_function_resources[%d].resource_uri", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("UDF code must load from a trusted Cloud Storage bucket or folder: %v", [authorized_udf_locations]),
        "keyActualValue": uri_problem(uri),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# --- Matching helpers ---
# --- toc-match begin: gcs v1 ---
# Bucket and object of a Cloud Storage URI: gs://BUCKET/OBJECT, or the path
# forms https://storage.googleapis.com/BUCKET/OBJECT and
# https://storage.cloud.google.com/BUCKET/OBJECT. Bare bucket names are
# accepted for allowlist entries. Anything else does not parse.
tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    startswith(lower(u), "gs://")
    rest := substring(u, 5, -1)
}

tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    startswith(lower(u), "https://storage.googleapis.com/")
    rest := substring(u, 31, -1)
}

tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    startswith(lower(u), "https://storage.cloud.google.com/")
    rest := substring(u, 33, -1)
}

tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    not contains(u, "://")
    not contains(u, "/")
    rest := u
}

tocm_gcs_parts(uri) := {"bucket": b, "object": o} {
    rest := tocm_gcs_path(uri)
    i := indexof(rest, "/")
    i > 0
    b := lower(substring(rest, 0, i))
    o := substring(rest, i + 1, -1)
}

tocm_gcs_parts(uri) := {"bucket": b, "object": ""} {
    rest := tocm_gcs_path(uri)
    not contains(rest, "/")
    rest != ""
    b := lower(rest)
}

# A URI is allowed when its bucket equals an entry's bucket and, if the entry
# names a folder (gs://bucket/folder/), the object sits inside that folder. A
# folder entry without a trailing "/" is read as a folder.
tocm_gcs_allowed(uri, allowed) {
    p := tocm_gcs_parts(uri)
    e := tocm_gcs_parts(allowed[_])
    p.bucket == e.bucket
    e.object == ""
}

tocm_gcs_allowed(uri, allowed) {
    p := tocm_gcs_parts(uri)
    e := tocm_gcs_parts(allowed[_])
    p.bucket == e.bucket
    e.object != ""
    folder := concat("", [trim_suffix(e.object, "/"), "/"])
    startswith(p.object, folder)
}
# --- toc-match end: gcs v1 ---

# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

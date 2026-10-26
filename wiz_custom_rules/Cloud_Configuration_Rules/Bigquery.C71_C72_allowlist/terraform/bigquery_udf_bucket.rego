package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Trusted GCS prefixes that may host User Defined Function code.
authorized_udf_uri_prefixes := {
    "gs://my-corp-trusted-scripts",
    "gs://partner-lib-bucket/v1/"
}

# --- Helpers ---
bucket_allowed(uri) {
    allowed := authorized_udf_uri_prefixes[_]
    startswith(uri, allowed)
}

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
        "keyExpectedValue": sprintf("UDF code must load from trusted buckets: %v", [authorized_udf_uri_prefixes]),
        "keyActualValue": sprintf("UDF source '%v' is not trusted", [uri]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

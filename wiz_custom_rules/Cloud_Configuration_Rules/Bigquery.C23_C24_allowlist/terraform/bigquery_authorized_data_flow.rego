package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Authorized data sources and destinations, matched as URI prefixes.
authorized_uri_prefixes := {
    "gs://my-corp-data-lake",
    "gs://partner-upload-bucket",
    "https://drive.google.com"
}

# --- Helpers ---
uri_allowed(uri) {
    allowed := authorized_uri_prefixes[_]
    startswith(uri, allowed)
}

# --- Logic ---
# Finding: external table reading from an unauthorized source.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    cfg := terraLib.getValueArrayOrObject(tbl.external_data_configuration)
    uri := cfg.source_uris[uidx]
    not uri_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].external_data_configuration.source_uris[%d]", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("source URIs must match the authorized prefixes: %v", [authorized_uri_prefixes]),
        "keyActualValue": sprintf("source URI '%v' is not authorized", [uri]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: load job reading from an unauthorized source.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    load := terraLib.getValueArrayOrObject(job.load)
    uri := load.source_uris[uidx]
    not uri_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].load.source_uris[%d]", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("source URIs must match the authorized prefixes: %v", [authorized_uri_prefixes]),
        "keyActualValue": sprintf("source URI '%v' is not authorized", [uri]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: extract job writing to an unauthorized destination.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    extract := terraLib.getValueArrayOrObject(job.extract)
    uri := extract.destination_uris[uidx]
    not uri_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].extract.destination_uris[%d]", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("destination URIs must match the authorized prefixes: %v", [authorized_uri_prefixes]),
        "keyActualValue": sprintf("destination URI '%v' is not authorized", [uri]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

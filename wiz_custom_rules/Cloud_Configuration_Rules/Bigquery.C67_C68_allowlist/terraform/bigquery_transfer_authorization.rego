package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher.
authorized_data_source_ids := {
    "google_cloud_storage",
    "scheduled_query"
}

authorized_destination_datasets := {
    "raw_ingestion_zone",
    "my_governed_dataset"
}

# Identities authorized to RUN transfers. In IaC this is enforceable at
# write time through service_account_name; unset means the applying user's
# identity, which the cloud matcher verifies at runtime via owner_info.
authorized_transfer_identities := {
    "etl-loader@my-project.iam.gserviceaccount.com",
    "backup-admin@my-project.iam.gserviceaccount.com"
}

# Trusted GCS path prefixes for storage-based transfers
authorized_gcs_path_prefixes := {
    "gs://trusted-corp-"
}

# --- Logic ---
# Finding: unauthorized data source.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    not authorized_data_source_ids[tc.data_source_id]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].data_source_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("data_source_id must be one of: %v", [authorized_data_source_ids]),
        "keyActualValue": sprintf("data_source_id is '%v'", [object.get(tc, "data_source_id", "unset")]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: unauthorized destination dataset.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    dest := sprintf("%v", [object.get(tc, "destination_dataset_id", "")])
    not destination_authorized(dest)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].destination_dataset_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("destination_dataset_id must be one of: %v", [authorized_destination_datasets]),
        "keyActualValue": sprintf("destination_dataset_id is '%v'", [dest]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# A literal id must be in the allowlist; an interpolation reference is
# authorized when it points at one of the allowlisted dataset ids.
destination_authorized(dest) {
    authorized_destination_datasets[dest]
}

destination_authorized(dest) {
    allowed := authorized_destination_datasets[_]
    contains(dest, allowed)
}

# Finding: transfer declared to run as an unauthorized service account.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    sa := object.get(tc, "service_account_name", "")
    sa != ""
    not authorized_transfer_identities[sa]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].service_account_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("service_account_name must be one of: %v", [authorized_transfer_identities]),
        "keyActualValue": sprintf("service_account_name is '%v'", [sa]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: GCS transfer reading from an untrusted path.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    tc.data_source_id == "google_cloud_storage"
    path := object.get(object.get(tc, "params", {}), "data_path_template", "")
    prefixes_matching := {p | p := authorized_gcs_path_prefixes[_]; startswith(path, p)}
    count(prefixes_matching) == 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].params.data_path_template", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("data_path_template must start with a trusted prefix: %v", [authorized_gcs_path_prefixes]),
        "keyActualValue": sprintf("data_path_template is '%v'", [path]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: GCS transfer deleting source files (destructive).
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    tc.data_source_id == "google_cloud_storage"
    object.get(object.get(tc, "params", {}), "delete_source_files", "false") == "true"

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].params.delete_source_files", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "delete_source_files must not be enabled",
        "keyActualValue": "transfer deletes source files after load",
        "resourceTags": object.get(tc, "labels", {}),
    }
}

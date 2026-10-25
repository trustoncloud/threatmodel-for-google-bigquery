package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher. Expirations are milliseconds.
authorized_locations := {"US", "us-central1"}

authorized_table_expirations_ms := {5184000000, 2592000000}

authorized_partition_expirations_ms := {5184000000}

# --- Logic ---
# Location names are case-insensitive: "us" and "US" are the same multi-region.
location_authorized(loc) {
    lower(authorized_locations[_]) == lower(loc)
}

# Finding: dataset in an unauthorized location.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    loc := ds.location
    not location_authorized(loc)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].location", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("location must be one of: %v", [authorized_locations]),
        "keyActualValue": sprintf("location is '%v'", [loc]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: location unset, so the dataset lands in the default US multi-region,
# and US is not authorized.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not ds.location
    not location_authorized("US")

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s]", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": sprintf("location must be one of: %v", [authorized_locations]),
        "keyActualValue": "location is not set (defaults to 'US')",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: default table expiration set to an unauthorized value.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    exp := to_number(ds.default_table_expiration_ms)
    exp != 0
    not authorized_table_expirations_ms[exp]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_table_expiration_ms", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("default_table_expiration_ms must be one of: %v", [authorized_table_expirations_ms]),
        "keyActualValue": sprintf("default_table_expiration_ms is %v", [exp]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: default partition expiration set to an unauthorized value.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    exp := to_number(ds.default_partition_expiration_ms)
    exp != 0
    not authorized_partition_expirations_ms[exp]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_partition_expiration_ms", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("default_partition_expiration_ms must be one of: %v", [authorized_partition_expirations_ms]),
        "keyActualValue": sprintf("default_partition_expiration_ms is %v", [exp]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

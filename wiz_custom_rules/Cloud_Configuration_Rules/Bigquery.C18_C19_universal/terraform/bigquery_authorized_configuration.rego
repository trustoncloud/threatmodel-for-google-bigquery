package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Universal Security Baseline (keep in sync with the cloud matcher):
# datasets must set a default table expiration, and time travel must stay
# within the 168h GCP default. BigQuery accepts 48 to 168 hours, so at 168
# the time travel check reports nothing: lower the value to enforce a
# shorter window.
max_time_travel_hours := 168

# --- Logic ---
# An external dataset holds no tables of its own: their data and lifetime
# are managed in the external source, so the dataset is out of scope.
is_external_dataset(ds) {
    ds.external_dataset_reference
}

# Finding: dataset with no default table expiration (infinite retention).
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not is_external_dataset(ds)
    to_number(object.get(ds, "default_table_expiration_ms", 0)) == 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_table_expiration_ms", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "default_table_expiration_ms must be set (no infinite retention)",
        "keyActualValue": "default_table_expiration_ms is not set",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: time travel window above the allowed maximum.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not is_external_dataset(ds)
    tt := to_number(ds.max_time_travel_hours)
    tt > max_time_travel_hours

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].max_time_travel_hours", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("max_time_travel_hours must be at most %v", [max_time_travel_hours]),
        "keyActualValue": sprintf("max_time_travel_hours is %v", [tt]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

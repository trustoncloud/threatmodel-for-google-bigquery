package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher: minimum time travel window in hours.
# Datasets that omit max_time_travel_hours get the GCP default of 168.
# BigQuery accepts 48 to 168 hours, so at 48 this check reports nothing:
# raise the value to enforce a longer window.
min_required_hours := 48

# --- Logic ---
# An external dataset has no time travel window, so it is out of scope.
is_external_dataset(ds) {
    ds.external_dataset_reference
}

WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not is_external_dataset(ds)
    tt := to_number(ds.max_time_travel_hours)
    tt < min_required_hours

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].max_time_travel_hours", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("max_time_travel_hours must be at least %v", [min_required_hours]),
        "keyActualValue": sprintf("max_time_travel_hours is %v", [tt]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher: the backup label must exist and carry
# an authorized schedule value. The label records the intended schedule only:
# it does not show that a backup exists, ran or can be restored, and tables
# and models are not checked.
backup_label_key := "backup_policy"

authorized_backup_schedules := {
    "daily",
    "weekly",
    "dr_critical",
    "legal_hold"
}

# --- Logic ---
# Finding: dataset with no backup label at all.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    labels := object.get(ds, "labels", {})
    not labels[backup_label_key]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].labels", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": sprintf("labels must include '%v' with one of: %v (the label records the intended backup schedule only; it does not show that a backup exists or can be restored)", [backup_label_key, authorized_backup_schedules]),
        "keyActualValue": sprintf("label '%v' is not set", [backup_label_key]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: backup label present but with an unauthorized value.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    val := ds.labels[backup_label_key]
    not authorized_backup_schedules[val]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].labels.%s", [name, backup_label_key]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("label '%v' must be one of: %v (the label records the intended backup schedule only; it does not show that a backup exists or can be restored)", [backup_label_key, authorized_backup_schedules]),
        "keyActualValue": sprintf("label '%v' is '%v'", [backup_label_key, val]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

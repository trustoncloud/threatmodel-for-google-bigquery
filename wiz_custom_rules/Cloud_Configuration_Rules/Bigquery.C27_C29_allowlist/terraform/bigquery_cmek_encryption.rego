package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher: a resource key must start with an
# authorized key (key-level) or match an authorized pinned version exactly.
authorized_kms_keys := {
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key",
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key/cryptoKeyVersions/5"
}

# --- Helpers ---
key_authorized(key) {
    allowed := authorized_kms_keys[_]
    startswith(key, allowed)
}

dataset_key(ds) := key {
    cfg := terraLib.getValueArrayOrObject(ds.default_encryption_configuration)
    key := cfg.kms_key_name
}

table_key(tbl) := key {
    cfg := terraLib.getValueArrayOrObject(tbl.encryption_configuration)
    key := cfg.kms_key_name
}

# --- Logic ---
# Finding: dataset without CMEK.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not dataset_key(ds)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_encryption_configuration.kms_key_name", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "default_encryption_configuration.kms_key_name must be set to an authorized CMEK",
        "keyActualValue": "dataset uses Google-managed encryption (no CMEK)",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: dataset CMEK not in the authorized set.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    key := dataset_key(ds)
    not key_authorized(key)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_encryption_configuration.kms_key_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("kms_key_name must match the authorized keys: %v", [authorized_kms_keys]),
        "keyActualValue": sprintf("kms_key_name is '%v'", [key]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: table without CMEK.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    not table_key(tbl)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].encryption_configuration.kms_key_name", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "encryption_configuration.kms_key_name must be set to an authorized CMEK",
        "keyActualValue": "table uses Google-managed encryption (no CMEK)",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: table CMEK not in the authorized set.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    key := table_key(tbl)
    not key_authorized(key)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].encryption_configuration.kms_key_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("kms_key_name must match the authorized keys: %v", [authorized_kms_keys]),
        "keyActualValue": sprintf("kms_key_name is '%v'", [key]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

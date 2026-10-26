package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal baseline: every dataset and table must use CMEK.

dataset_key(ds) := key {
    cfg := terraLib.getValueArrayOrObject(ds.default_encryption_configuration)
    key := cfg.kms_key_name
}

table_key(tbl) := key {
    cfg := terraLib.getValueArrayOrObject(tbl.encryption_configuration)
    key := cfg.kms_key_name
}

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
        "keyExpectedValue": "default_encryption_configuration.kms_key_name must be set (CMEK required)",
        "keyActualValue": "dataset uses Google-managed encryption (no CMEK)",
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
        "keyExpectedValue": "encryption_configuration.kms_key_name must be set (CMEK required)",
        "keyActualValue": "table uses Google-managed encryption (no CMEK)",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

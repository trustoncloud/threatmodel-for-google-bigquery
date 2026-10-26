package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher. Keys use the format "prefix:value".
authorized_entities := {
    "specialGroup:projectOwners",
    "specialGroup:projectWriters",
    "specialGroup:projectReaders",
    "group:data-admins@yourcompany.com",
    "group:data-team@yourcompany.com",
    "user:admin@yourcompany.com"
}

# --- Helpers ---
# Normalize an access entry (inline block or standalone resource) to the
# "prefix:value" form used by the allowlist.
get_entity(entry) := val {
    e := object.get(entry, "user_by_email", "")
    e != ""
    val := sprintf("user:%v", [e])
} else := val {
    e := object.get(entry, "group_by_email", "")
    e != ""
    val := sprintf("group:%v", [e])
} else := val {
    e := object.get(entry, "domain", "")
    e != ""
    val := sprintf("domain:%v", [e])
} else := val {
    e := object.get(entry, "special_group", "")
    e != ""
    val := sprintf("specialGroup:%v", [e])
} else := val {
    e := object.get(entry, "iam_member", "")
    e != ""
    val := e # iam_member includes the prefix
} else := val {
    v := terraLib.getValueArrayOrObject(entry.view)
    val := sprintf("view:%v", [v.table_id])
} else := val {
    r := terraLib.getValueArrayOrObject(entry.routine)
    val := sprintf("routine:%v", [r.routine_id])
} else := val {
    d := terraLib.getValueArrayOrObject(entry.dataset)
    ref := terraLib.getValueArrayOrObject(d.dataset)
    val := sprintf("dataset:%v", [ref.dataset_id])
}

# --- Logic ---
# Inline access blocks on the dataset.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    entry := terraLib.getArray(ds.access)[idx]
    entity := get_entity(entry)
    not authorized_entities[entity]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].access[%d]", [name, idx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access entries must be in the authorized set: %v", [authorized_entities]),
        "keyActualValue": sprintf("access entry '%v' is not authorized", [entity]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Standalone google_bigquery_dataset_access resources.
WizPolicy[result] {
    document := input.document[i]
    acc := document.resource.google_bigquery_dataset_access[name]
    entity := get_entity(acc)
    not authorized_entities[entity]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset_access",
        "resourceName": terraLib.get_resource_name(acc, name),
        "searchKey": sprintf("google_bigquery_dataset_access[%s]", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access entries must be in the authorized set: %v", [authorized_entities]),
        "keyActualValue": sprintf("access entry '%v' is not authorized", [entity]),
        "resourceTags": object.get(acc, "labels", {}),
    }
}

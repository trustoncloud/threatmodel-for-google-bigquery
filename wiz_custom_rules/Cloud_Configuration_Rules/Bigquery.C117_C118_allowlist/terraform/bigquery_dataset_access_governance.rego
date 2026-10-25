package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher.
authorized_domains := {
    "yourcompany.com",
    "subsidiary.com",
    "gserviceaccount.com"
}

blocked_public_members := {"allUsers", "allAuthenticatedUsers"}

# Mandatory access entity: must be present on every dataset, either as an
# inline access block or as a standalone google_bigquery_dataset_access.
required_role := "OWNER"

required_group := "data-admins@yourcompany.com"

# --- Helpers ---
# Email carried by an access entry (inline block or standalone resource).
entry_email(entry) := email {
    email := object.get(entry, "user_by_email", "")
    email != ""
} else := email {
    email := object.get(entry, "group_by_email", "")
    email != ""
} else := email {
    member := object.get(entry, "iam_member", "")
    parts := split(member, ":")
    count(parts) == 2
    email := parts[1]
} else := email {
    email := object.get(entry, "domain", "")
    email != ""
}

email_authorized(email) {
    domain := authorized_domains[_]
    endswith(email, domain)
}

is_public_entry(entry) {
    blocked_public_members[object.get(entry, "special_group", "")]
}

is_public_entry(entry) {
    blocked_public_members[object.get(entry, "iam_member", "")]
}

is_required_admin(entry) {
    object.get(entry, "role", "") == required_role
    object.get(entry, "group_by_email", "") == required_group
}

# The mandatory admin exists for a dataset when it appears inline on the
# dataset or on a standalone access resource referencing it (by literal
# dataset_id or by "${google_bigquery_dataset.<name>...}" interpolation).
has_required_admin(ds, dsname) {
    entry := terraLib.getArray(ds.access)[_]
    is_required_admin(entry)
}

has_required_admin(ds, dsname) {
    acc := input.document[_].resource.google_bigquery_dataset_access[_]
    is_required_admin(acc)
    access_targets_dataset(acc, ds, dsname)
}

access_targets_dataset(acc, ds, dsname) {
    contains(sprintf("%v", [acc.dataset_id]), dsname)
}

access_targets_dataset(acc, ds, dsname) {
    acc.dataset_id == ds.dataset_id
}

# --- Logic ---
# Finding: public access granted inline.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    entry := terraLib.getArray(ds.access)[idx]
    is_public_entry(entry)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].access[%d]", [name, idx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access must not include public members: %v", [blocked_public_members]),
        "keyActualValue": "access entry grants public access",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: public access granted via a standalone resource.
WizPolicy[result] {
    document := input.document[i]
    acc := document.resource.google_bigquery_dataset_access[name]
    is_public_entry(acc)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset_access",
        "resourceName": terraLib.get_resource_name(acc, name),
        "searchKey": sprintf("google_bigquery_dataset_access[%s]", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access must not include public members: %v", [blocked_public_members]),
        "keyActualValue": "access entry grants public access",
        "resourceTags": object.get(acc, "labels", {}),
    }
}

# Finding: inline identity from an unauthorized domain.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    entry := terraLib.getArray(ds.access)[idx]
    email := entry_email(entry)
    not email_authorized(email)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].access[%d]", [name, idx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access identities must belong to authorized domains: %v", [authorized_domains]),
        "keyActualValue": sprintf("'%v' belongs to an unauthorized domain", [email]),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: standalone identity from an unauthorized domain.
WizPolicy[result] {
    document := input.document[i]
    acc := document.resource.google_bigquery_dataset_access[name]
    email := entry_email(acc)
    not email_authorized(email)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset_access",
        "resourceName": terraLib.get_resource_name(acc, name),
        "searchKey": sprintf("google_bigquery_dataset_access[%s]", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access identities must belong to authorized domains: %v", [authorized_domains]),
        "keyActualValue": sprintf("'%v' belongs to an unauthorized domain", [email]),
        "resourceTags": object.get(acc, "labels", {}),
    }
}

# Finding: dataset without the mandatory admin group (drift detection).
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not has_required_admin(ds, name)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].access", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": sprintf("'%v' must hold role %v (inline or via google_bigquery_dataset_access)", [required_group, required_role]),
        "keyActualValue": "mandatory admin group is not granted on this dataset",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

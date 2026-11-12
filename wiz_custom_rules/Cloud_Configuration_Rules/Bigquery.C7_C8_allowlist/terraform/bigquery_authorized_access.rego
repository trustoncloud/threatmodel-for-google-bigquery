package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher. Keys use the format "prefix:value".
# A service account is written "user:<email>", the way the dataset access
# list files it; the same entry approves it in IAM grants, where it appears
# as "serviceAccount:<email>".
# An authorized view, routine or dataset is written with its project ID,
# dataset and ID: "view:<project-id>.<dataset>.<table>",
# "routine:<project-id>.<dataset>.<routine>", "dataset:<project-id>.<dataset>".
authorized_entities := {
    "specialGroup:projectOwners",
    "specialGroup:projectWriters",
    "specialGroup:projectReaders",
    "group:data-admins@yourcompany.com",
    "group:data-team@yourcompany.com",
    "user:admin@yourcompany.com",
    "user:etl-loader@my-project.iam.gserviceaccount.com",
    "view:my-project.reporting.sales_summary",
    "routine:my-project.reporting.mask_email",
    "dataset:my-project.reporting"
}

# --- Helpers ---
# Normalize an access entry (inline block or standalone resource) to the
# "prefix:value" form used by the allowlist. A view, routine or dataset is
# named by project, dataset and ID together, so the same ID elsewhere is a
# different entity. A part that is left out, or set from a variable or
# another resource, stays in the name as written and matches no entry.
access_entity(entry) := val {
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
    val := sprintf("view:%v.%v.%v", [object.get(v, "project_id", ""), object.get(v, "dataset_id", ""), object.get(v, "table_id", "")])
} else := val {
    r := terraLib.getValueArrayOrObject(entry.routine)
    val := sprintf("routine:%v.%v.%v", [object.get(r, "project_id", ""), object.get(r, "dataset_id", ""), object.get(r, "routine_id", "")])
} else := val {
    d := terraLib.getValueArrayOrObject(entry.dataset)
    ref := terraLib.getValueArrayOrObject(d.dataset)
    val := sprintf("dataset:%v.%v", [object.get(ref, "project_id", ""), object.get(ref, "dataset_id", "")])
}

# An access entry or IAM member is authorized when it is in the set as
# written. A service account member is also authorized by its
# "user:<email>" entry.
member_authorized(member) {
    authorized_entities[member]
}

member_authorized(member) {
    email := trim_prefix(member, "serviceAccount:")
    email != member
    authorized_entities[sprintf("user:%s", [email])]
}

# IAM grants on a dataset, a table or a view, in the three forms the
# provider offers.
iam_member_types := {
    "google_bigquery_dataset_iam_member",
    "google_bigquery_table_iam_member"
}

iam_binding_types := {
    "google_bigquery_dataset_iam_binding",
    "google_bigquery_table_iam_binding"
}

iam_policy_types := {
    "google_bigquery_dataset_iam_policy",
    "google_bigquery_table_iam_policy"
}

# The policy form takes its bindings from a google_iam_policy data source,
# which policy_data names.
policy_source_name(res) := source {
    ref := sprintf("%v", [object.get(res, "policy_data", "")])
    found := regex.find_all_string_submatch_n(`^\$\{\s*data\.google_iam_policy\.([A-Za-z0-9_-]+)\.policy_data\s*\}$`, ref, 1)
    count(found) == 1
    source := found[0][1]
}

# The data source is read from the file that declares the policy: a data
# source with the same name in another module is a different policy. Bindings
# built with a dynamic block are not in the source as text, so such a policy
# cannot be read.
policy_source(document, res) := source {
    source := document.data.google_iam_policy[policy_source_name(res)]
    not source.dynamic
}

policy_members(document, res) := {member |
    binding := terraLib.getArray(policy_source(document, res).binding)[_]
    member := terraLib.getArray(binding.members)[_]
}

policy_is_readable(document, res) {
    policy_source(document, res)
}

# A dynamic block sits under a "dynamic" key, as a list of blocks or as one
# object keyed by the block name.
has_dynamic_access(ds) {
    ds.dynamic[_].access
}

has_dynamic_access(ds) {
    ds.dynamic.access
}

# --- Logic ---
# Inline access blocks on the dataset.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    entry := terraLib.getArray(ds.access)[idx]
    entity := access_entity(entry)
    not member_authorized(entity)

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

# Access entries built with a dynamic block are not in the source as text,
# so the dataset is reported.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    has_dynamic_access(ds)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].dynamic.access", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "access blocks must be written out (no dynamic block), so each entry can be checked",
        "keyActualValue": "the entries a dynamic access block grants cannot be read from the source",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Standalone google_bigquery_dataset_access resources.
WizPolicy[result] {
    document := input.document[i]
    acc := document.resource.google_bigquery_dataset_access[name]
    entity := access_entity(acc)
    not member_authorized(entity)

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

# IAM member resources on a dataset, table or view. A member set from a
# variable or another resource is not known until apply, so it is never
# authorized.
WizPolicy[result] {
    document := input.document[i]
    rtype := iam_member_types[_]
    res := document.resource[rtype][name]
    member := object.get(res, "member", "")
    not member_authorized(member)

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("%s[%s].member", [rtype, name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("IAM members must be in the authorized set: %v", [authorized_entities]),
        "keyActualValue": sprintf("member '%v' is not authorized", [member]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# IAM binding resources on a dataset, table or view.
WizPolicy[result] {
    document := input.document[i]
    rtype := iam_binding_types[_]
    res := document.resource[rtype][name]
    member := terraLib.getArray(object.get(res, "members", []))[idx]
    not member_authorized(member)

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("%s[%s].members[%d]", [rtype, name, idx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("IAM members must be in the authorized set: %v", [authorized_entities]),
        "keyActualValue": sprintf("member '%v' is not authorized", [member]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# IAM policy resources on a dataset, table or view.
WizPolicy[result] {
    document := input.document[i]
    rtype := iam_policy_types[_]
    res := document.resource[rtype][name]
    member := policy_members(document, res)[_]
    not member_authorized(member)

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("%s[%s].policy_data", [rtype, name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("IAM members must be in the authorized set: %v", [authorized_entities]),
        "keyActualValue": sprintf("member '%v' is not authorized", [member]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# An IAM policy whose bindings the source does not show.
WizPolicy[result] {
    document := input.document[i]
    rtype := iam_policy_types[_]
    res := document.resource[rtype][name]
    not policy_is_readable(document, res)

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("%s[%s].policy_data", [rtype, name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "policy_data must name a google_iam_policy data source in the same file, with its binding blocks written out (no dynamic block), so its members can be checked",
        "keyActualValue": "the members this policy grants cannot be read from the source",
        "resourceTags": object.get(res, "labels", {}),
    }
}

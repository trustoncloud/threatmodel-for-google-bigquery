package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Exact set of entities authorized on Data Catalog policy tags (sensitive
# columns). Keys use the IAM member format "prefix:value".
authorized_principals := {
    "group:sensitive-data-readers@example.com",
    "user:ciso@example.com",
    "serviceAccount:etl-pipeline@project-id.iam.gserviceaccount.com"
}

# The role that reads the columns under a policy tag. Granted on a project,
# folder or organization, it reaches every policy tag below.
fine_grained_reader_role := "roles/datacatalog.categoryFineGrainedReader"

# --- Helpers ---
# Grants on a policy tag or on its taxonomy, in the three forms the provider
# offers. Any role there is in scope.
tag_member_types := {
    "google_data_catalog_policy_tag_iam_member",
    "google_data_catalog_taxonomy_iam_member"
}

tag_binding_types := {
    "google_data_catalog_policy_tag_iam_binding",
    "google_data_catalog_taxonomy_iam_binding"
}

tag_policy_types := {
    "google_data_catalog_policy_tag_iam_policy",
    "google_data_catalog_taxonomy_iam_policy"
}

# Grants on a project, folder or organization. Only the reader role is in
# scope there.
scope_member_types := {
    "google_project_iam_member",
    "google_folder_iam_member",
    "google_organization_iam_member"
}

scope_binding_types := {
    "google_project_iam_binding",
    "google_folder_iam_binding",
    "google_organization_iam_binding"
}

scope_policy_types := {
    "google_project_iam_policy",
    "google_folder_iam_policy",
    "google_organization_iam_policy"
}

# On a project, folder or organization only a grant that names the reader
# role is in scope. A role set from a variable or another resource is not
# known until apply, and such a grant is not read.
role_in_scope(role) {
    role == fine_grained_reader_role
}

scope_detail(role) := "holds the Fine-Grained Reader role on a project, folder or organization" {
    role == fine_grained_reader_role
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

policy_bindings(document, res) := [binding |
    binding := terraLib.getArray(policy_source(document, res).binding)[_]
]

policy_is_readable(document, res) {
    policy_source(document, res)
}

# Every grant in scope, with the resource that makes it.
grants[grant] {
    document := input.document[i]
    rtype := tag_member_types[_]
    res := document.resource[rtype][name]
    grant := {"documentId": document.id, "resourceType": rtype, "name": name, "res": res,
              "member": object.get(res, "member", ""),
              "searchKey": sprintf("%s[%s].member", [rtype, name]),
              "detail": "is granted on a policy tag or taxonomy"}
}

grants[grant] {
    document := input.document[i]
    rtype := tag_binding_types[_]
    res := document.resource[rtype][name]
    member := terraLib.getArray(object.get(res, "members", []))[idx]
    grant := {"documentId": document.id, "resourceType": rtype, "name": name, "res": res,
              "member": member,
              "searchKey": sprintf("%s[%s].members[%d]", [rtype, name, idx]),
              "detail": "is granted on a policy tag or taxonomy"}
}

grants[grant] {
    document := input.document[i]
    rtype := tag_policy_types[_]
    res := document.resource[rtype][name]
    binding := policy_bindings(document, res)[_]
    member := terraLib.getArray(object.get(binding, "members", []))[_]
    grant := {"documentId": document.id, "resourceType": rtype, "name": name, "res": res,
              "member": member,
              "searchKey": sprintf("%s[%s].policy_data", [rtype, name]),
              "detail": "is granted on a policy tag or taxonomy"}
}

grants[grant] {
    document := input.document[i]
    rtype := scope_member_types[_]
    res := document.resource[rtype][name]
    role := object.get(res, "role", "")
    role_in_scope(role)
    grant := {"documentId": document.id, "resourceType": rtype, "name": name, "res": res,
              "member": object.get(res, "member", ""),
              "searchKey": sprintf("%s[%s].member", [rtype, name]),
              "detail": scope_detail(role)}
}

grants[grant] {
    document := input.document[i]
    rtype := scope_binding_types[_]
    res := document.resource[rtype][name]
    role := object.get(res, "role", "")
    role_in_scope(role)
    member := terraLib.getArray(object.get(res, "members", []))[idx]
    grant := {"documentId": document.id, "resourceType": rtype, "name": name, "res": res,
              "member": member,
              "searchKey": sprintf("%s[%s].members[%d]", [rtype, name, idx]),
              "detail": scope_detail(role)}
}

grants[grant] {
    document := input.document[i]
    rtype := scope_policy_types[_]
    res := document.resource[rtype][name]
    binding := policy_bindings(document, res)[_]
    role := object.get(binding, "role", "")
    role_in_scope(role)
    member := terraLib.getArray(object.get(binding, "members", []))[_]
    grant := {"documentId": document.id, "resourceType": rtype, "name": name, "res": res,
              "member": member,
              "searchKey": sprintf("%s[%s].policy_data", [rtype, name]),
              "detail": scope_detail(role)}
}

# --- Logic ---
# Finding: a grant in scope to an entity outside the authorized set. A member
# set from a variable or another resource is not known until apply, so it is
# never authorized.
WizPolicy[result] {
    grant := grants[_]
    not authorized_principals[grant.member]

    result := {
        "documentId": grant.documentId,
        "resourceType": grant.resourceType,
        "resourceName": terraLib.get_resource_name(grant.res, grant.name),
        "searchKey": grant.searchKey,
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("grants on a policy tag or taxonomy, and Fine-Grained Reader grants on a project, folder or organization, must be in the authorized set: %v", [authorized_principals]),
        "keyActualValue": sprintf("'%v' %s", [grant.member, grant.detail]),
        "resourceTags": object.get(grant.res, "labels", {}),
    }
}

# Finding: an IAM policy whose bindings the source does not show. A project,
# folder or organization policy that cannot be read is out of scope, since
# nothing shows that it grants the reader role.
WizPolicy[result] {
    document := input.document[i]
    rtype := tag_policy_types[_]
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

# --- Matching helpers ---
# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

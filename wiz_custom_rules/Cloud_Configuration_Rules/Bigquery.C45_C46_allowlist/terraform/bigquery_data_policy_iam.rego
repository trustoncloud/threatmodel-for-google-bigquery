package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Exact set of IAM members authorized on BigQuery data policies (masked
# reads and column-level security exemptions).
authorized_principals := {
    "user:admin@example.com",
    "group:data-scientists@example.com",
    "serviceAccount:masked-reader@my-project.iam.gserviceaccount.com",
    "domain:example.com"
}

# The role that reads masked columns. Granted on a project, folder or
# organization, it reaches every data policy below.
masked_reader_role := "roles/bigquerydatapolicy.maskedReader"

# --- Helpers ---
# Grants on a project, folder or organization. Only the Masked Reader role
# is in scope there; any role on a data policy is in scope.
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
    role == masked_reader_role
}

scope_detail(role) := "holds the Masked Reader role on a project, folder or organization" {
    role == masked_reader_role
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
    res := document.resource.google_bigquery_datapolicy_data_policy_iam_member[name]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_datapolicy_data_policy_iam_member",
              "name": name, "res": res, "member": object.get(res, "member", ""),
              "searchKey": sprintf("google_bigquery_datapolicy_data_policy_iam_member[%s].member", [name]),
              "detail": "is granted on a data policy"}
}

grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_datapolicy_data_policy_iam_binding[name]
    member := terraLib.getArray(object.get(res, "members", []))[idx]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_datapolicy_data_policy_iam_binding",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_bigquery_datapolicy_data_policy_iam_binding[%s].members[%d]", [name, idx]),
              "detail": "is granted on a data policy"}
}

grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_datapolicy_data_policy_iam_policy[name]
    binding := policy_bindings(document, res)[_]
    member := terraLib.getArray(object.get(binding, "members", []))[_]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_datapolicy_data_policy_iam_policy",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_bigquery_datapolicy_data_policy_iam_policy[%s].policy_data", [name]),
              "detail": "is granted on a data policy"}
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
# Finding: a grant in scope to a member outside the authorized set. A member
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
        "keyExpectedValue": sprintf("grants on a data policy, and Masked Reader grants on a project, folder or organization, must be in the authorized set: %v", [authorized_principals]),
        "keyActualValue": sprintf("'%v' %s", [grant.member, grant.detail]),
        "resourceTags": object.get(grant.res, "labels", {}),
    }
}

# Finding: an IAM policy whose bindings the source does not show. A project,
# folder or organization policy that cannot be read is out of scope, since
# nothing shows that it grants the reader role.
WizPolicy[result] {
    document := input.document[i]
    rtype := {"google_bigquery_datapolicy_data_policy_iam_policy"}[_]
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

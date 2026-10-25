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

# --- Helpers ---
# Collect every grant across the IAM declaration forms, preserving source
# context per entry. Any role on a policy tag is in scope.
tag_grants[grant] {
    document := input.document[i]
    res := document.resource.google_data_catalog_policy_tag_iam_member[name]
    grant := {"documentId": document.id, "resourceType": "google_data_catalog_policy_tag_iam_member",
              "name": name, "res": res, "member": res.member,
              "searchKey": sprintf("google_data_catalog_policy_tag_iam_member[%s].member", [name])}
}

tag_grants[grant] {
    document := input.document[i]
    res := document.resource.google_data_catalog_policy_tag_iam_binding[name]
    member := res.members[midx]
    grant := {"documentId": document.id, "resourceType": "google_data_catalog_policy_tag_iam_binding",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_data_catalog_policy_tag_iam_binding[%s].members[%d]", [name, midx])}
}

tag_grants[grant] {
    document := input.document[i]
    res := document.resource.google_data_catalog_policy_tag_iam_policy[name]
    policy := json.unmarshal(res.policy_data)
    binding := policy.bindings[bidx]
    member := binding.members[midx]
    grant := {"documentId": document.id, "resourceType": "google_data_catalog_policy_tag_iam_policy",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_data_catalog_policy_tag_iam_policy[%s].policy_data", [name])}
}

# --- Logic ---
# Finding: policy tag grant to an entity outside the authorized set.
WizPolicy[result] {
    grant := tag_grants[_]
    not authorized_principals[grant.member]

    result := {
        "documentId": grant.documentId,
        "resourceType": grant.resourceType,
        "resourceName": terraLib.get_resource_name(grant.res, grant.name),
        "searchKey": grant.searchKey,
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("policy tag grants must be in the authorized set: %v", [authorized_principals]),
        "keyActualValue": sprintf("'%v' is granted on a policy tag", [grant.member]),
        "resourceTags": object.get(grant.res, "labels", {}),
    }
}

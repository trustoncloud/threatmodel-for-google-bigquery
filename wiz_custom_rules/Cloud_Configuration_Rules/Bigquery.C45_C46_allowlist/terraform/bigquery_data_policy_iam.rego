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

# --- Helpers ---
# Collect every grant across the IAM declaration forms, preserving source
# context per entry.
data_policy_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_datapolicy_data_policy_iam_member[name]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_datapolicy_data_policy_iam_member",
              "name": name, "res": res, "member": res.member,
              "searchKey": sprintf("google_bigquery_datapolicy_data_policy_iam_member[%s].member", [name])}
}

data_policy_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_datapolicy_data_policy_iam_binding[name]
    member := res.members[midx]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_datapolicy_data_policy_iam_binding",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_bigquery_datapolicy_data_policy_iam_binding[%s].members[%d]", [name, midx])}
}

data_policy_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_datapolicy_data_policy_iam_policy[name]
    policy := json.unmarshal(res.policy_data)
    binding := policy.bindings[bidx]
    member := binding.members[midx]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_datapolicy_data_policy_iam_policy",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_bigquery_datapolicy_data_policy_iam_policy[%s].policy_data", [name])}
}

# --- Logic ---
# Finding: data policy grant to a member outside the authorized set.
WizPolicy[result] {
    grant := data_policy_grants[_]
    not authorized_principals[grant.member]

    result := {
        "documentId": grant.documentId,
        "resourceType": grant.resourceType,
        "resourceName": terraLib.get_resource_name(grant.res, grant.name),
        "searchKey": grant.searchKey,
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("data policy grants must be in the authorized set: %v", [authorized_principals]),
        "keyActualValue": sprintf("'%v' is granted on a data policy", [grant.member]),
        "resourceTags": object.get(grant.res, "labels", {}),
    }
}

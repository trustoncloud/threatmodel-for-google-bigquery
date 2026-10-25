package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# 1. Domains whose identities may hold subscriber-capable roles.
authorized_subscriber_domains := {
    "yourcompany.com",
    "partner-domain.com"
}

# 2. Roles that grant subscription capability.
subscriber_roles := {
    "roles/analyticshub.subscriber",
    "roles/analyticshub.admin"
}

# --- Helpers ---
blocked_public_principals := {"allUsers", "allAuthenticatedUsers"}

member_authorized(m) {
    not blocked_public_principals[m]
    parts := split(m, "@")
    count(parts) == 2
    domain := authorized_subscriber_domains[_]
    endswith(parts[1], domain)
}

# Collect every subscriber-role grant across the IAM declaration forms of
# both Analytics Hub resource types, preserving source context per entry.
subscriber_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_analytics_hub_data_exchange_iam_member[name]
    subscriber_roles[res.role]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_analytics_hub_data_exchange_iam_member",
              "name": name, "res": res, "member": res.member,
              "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange_iam_member[%s].member", [name])}
}

subscriber_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_analytics_hub_data_exchange_iam_binding[name]
    subscriber_roles[res.role]
    member := res.members[midx]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_analytics_hub_data_exchange_iam_binding",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange_iam_binding[%s].members[%d]", [name, midx])}
}

subscriber_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_analytics_hub_listing_iam_member[name]
    subscriber_roles[res.role]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_analytics_hub_listing_iam_member",
              "name": name, "res": res, "member": res.member,
              "searchKey": sprintf("google_bigquery_analytics_hub_listing_iam_member[%s].member", [name])}
}

subscriber_grants[grant] {
    document := input.document[i]
    res := document.resource.google_bigquery_analytics_hub_listing_iam_binding[name]
    subscriber_roles[res.role]
    member := res.members[midx]
    grant := {"documentId": document.id, "resourceType": "google_bigquery_analytics_hub_listing_iam_binding",
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("google_bigquery_analytics_hub_listing_iam_binding[%s].members[%d]", [name, midx])}
}

# _iam_policy form: policy_data parses when declared as inline JSON; a
# google_iam_policy data-source reference is resolved by the Wiz parser.
iam_policy_types := {
    "google_bigquery_analytics_hub_data_exchange_iam_policy",
    "google_bigquery_analytics_hub_listing_iam_policy"
}

subscriber_grants[grant] {
    document := input.document[i]
    rtype := iam_policy_types[_]
    res := document.resource[rtype][name]
    policy := json.unmarshal(res.policy_data)
    binding := policy.bindings[bidx]
    subscriber_roles[binding.role]
    member := binding.members[midx]
    grant := {"documentId": document.id, "resourceType": rtype,
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("%s[%s].policy_data", [rtype, name])}
}

# --- Logic ---
# Finding: subscriber-capable role granted to an unauthorized identity.
WizPolicy[result] {
    grant := subscriber_grants[_]
    not member_authorized(grant.member)

    result := {
        "documentId": grant.documentId,
        "resourceType": grant.resourceType,
        "resourceName": terraLib.get_resource_name(grant.res, grant.name),
        "searchKey": grant.searchKey,
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("subscriber roles may only be granted to identities from: %v", [authorized_subscriber_domains]),
        "keyActualValue": sprintf("'%v' holds a subscriber-capable role", [grant.member]),
        "resourceTags": object.get(grant.res, "labels", {}),
    }
}

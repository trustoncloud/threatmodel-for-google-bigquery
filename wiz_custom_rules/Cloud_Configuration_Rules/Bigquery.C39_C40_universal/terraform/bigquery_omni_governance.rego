package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Constraints that must stay enforced (BigQuery Omni disabled). The matcher
# flags declarations that create Omni connections or weaken the ban; absence
# of an org policy in IaC is not a finding (the ban may be set elsewhere).
omni_constraint_names := {
    "constraints/bigquery.disableBQOmniAWS",
    "constraints/bigquery.disableBQOmniAzure",
    "bigquery.disableBQOmniAWS",
    "bigquery.disableBQOmniAzure"
}

# --- Helpers ---
is_target_constraint(c) {
    omni_constraint_names[c]
}

# --- Logic ---
# Finding: any Omni connection declared (the ban means none are allowed).
WizPolicy[result] {
    document := input.document[i]
    conn := document.resource.google_bigquery_connection[name]
    omni_block := {"aws", "azure"}[_]
    conn[omni_block]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_connection",
        "resourceName": terraLib.get_resource_name(conn, name),
        "searchKey": sprintf("google_bigquery_connection[%s].%s", [name, omni_block]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "BigQuery Omni is disabled by policy; no Omni connections may be declared",
        "keyActualValue": sprintf("connection declares an %v block", [omni_block]),
        "resourceTags": object.get(conn, "labels", {}),
    }
}

# Finding: new-style org policy weakening the Omni ban.
WizPolicy[result] {
    document := input.document[i]
    pol := document.resource.google_org_policy_policy[name]
    constraint_of_policy_name(pol)
    spec := terraLib.getValueArrayOrObject(pol.spec)
    rule := terraLib.getArray(spec.rules)[ridx]
    upper(sprintf("%v", [object.get(rule, "enforce", "TRUE")])) != "TRUE"

    result := {
        "documentId": document.id,
        "resourceType": "google_org_policy_policy",
        "resourceName": terraLib.get_resource_name(pol, name),
        "searchKey": sprintf("google_org_policy_policy[%s].spec.rules[%d].enforce", [name, ridx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "the BigQuery Omni disable constraints must stay enforced",
        "keyActualValue": "policy declares the Omni constraint unenforced",
        "resourceTags": object.get(pol, "labels", {}),
    }
}

constraint_of_policy_name(pol) {
    c := omni_constraint_names[_]
    contains(sprintf("%v", [pol.name]), c)
}

# Finding: legacy org policy resources weakening the Omni ban.
legacy_org_policy_types := {
    "google_organization_policy",
    "google_folder_organization_policy",
    "google_project_organization_policy"
}

WizPolicy[result] {
    document := input.document[i]
    rtype := legacy_org_policy_types[_]
    pol := document.resource[rtype][name]
    is_target_constraint(pol.constraint)
    bp := terraLib.getValueArrayOrObject(pol.boolean_policy)
    bp.enforced != true

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(pol, name),
        "searchKey": sprintf("%s[%s].boolean_policy.enforced", [rtype, name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "the BigQuery Omni disable constraints must stay enforced",
        "keyActualValue": "policy declares the Omni constraint unenforced",
        "resourceTags": object.get(pol, "labels", {}),
    }
}

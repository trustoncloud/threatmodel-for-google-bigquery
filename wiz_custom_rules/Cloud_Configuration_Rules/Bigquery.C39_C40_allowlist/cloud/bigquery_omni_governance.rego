package wiz

# --- Configuration ---
# Projects authorized to use BigQuery Omni, by project id. Authorized
# projects are exempt from the Omni disable constraints; everywhere else
# the constraints must be enforced.
authorized_omni_projects := {
    "omni-analytics-prod"
}

target_constraints := {
    "constraints/bigquery.disableBQOmniAWS",
    "constraints/bigquery.disableBQOmniAzure"
}

# --- Logic ---
default result := "pass"

# Project payloads carry the effective org policies, inherited ones included,
# as the top-level organizationPolicies array (null when unavailable).
is_supported_scope {
    input.projectId
}

org_policies := p {
    p := input.organizationPolicies
    p != null
} else := []

constraint_enforced(c) {
    pol := org_policies[_]
    pol.constraint == c
    pol.booleanPolicy.enforced == true
}

missing_constraints[c] {
    c := target_constraints[_]
    not constraint_enforced(c)
}

# Projects on the allowlist may run without the Omni ban; organizations
# cannot be exempted.
is_exempt {
    authorized_omni_projects[input.projectId]
}

result := "skip" {
    not is_supported_scope
} else := "pass" {
    is_exempt
} else := "fail" {
    count(missing_constraints) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Omni disable constraints not enforced: %v", [missing_constraints]) {
    result == "fail"
} else := "BigQuery Omni is disabled by org policy, or this project is authorized to use Omni"

expectedConfiguration := sprintf("These org policy constraints must be enforced unless the project is authorized for Omni: %v", [target_constraints])

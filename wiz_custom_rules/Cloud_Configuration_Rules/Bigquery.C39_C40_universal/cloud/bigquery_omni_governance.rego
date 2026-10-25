package wiz

# --- Configuration ---
# Universal Mode: these constraints must be ENFORCED (BigQuery Omni disabled).
# Evaluated on each project's effective policies, so an org-level ban
# reaches every project and a project-level override is caught.
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

# Helper: a constraint is enforced when its boolean policy is set to true
constraint_enforced(c) {
    pol := org_policies[_]
    pol.constraint == c
    pol.booleanPolicy.enforced == true
}

# Failure: any target constraint missing from this scope or not enforced
missing_constraints[c] {
    c := target_constraints[_]
    not constraint_enforced(c)
}

# --- Aggregation ---
result := "skip" {
    not is_supported_scope
} else := "fail" {
    count(missing_constraints) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Omni disable constraints not enforced: %v", [missing_constraints]) {
    result == "fail"
} else := "BigQuery Omni is disabled by org policy"

expectedConfiguration := sprintf("These org policy constraints must be enforced: %v", [target_constraints])

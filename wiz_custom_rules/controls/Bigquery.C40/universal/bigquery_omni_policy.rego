package wiz

# --- Configuration ---
# Universal Mode checks that these specific constraints are ENFORCED (Disabled).
target_constraints := {
    "constraints/bigquery.disableBQOmniAWS",
    "constraints/bigquery.disableBQOmniAzure"
}

# --- Logic ---
default result := "pass"

is_org_policy { input.type == "google_organization_policy" }

# 1. Check if the input is one of the Omni constraints
is_target_constraint {
    is_org_policy
    # Classic iteration: Check if input constraint matches any in our list
    constraint_name := input.properties.constraint
    target_constraints[constraint_name]
}

# 2. Check if Enforcement is Missing or False
# We want 'enforced: true' (which means Omni is DISABLED).
fail_policy_not_enforced {
    is_target_constraint
    # Default to false if the field is missing
    is_enforced := object.get(input.properties.booleanPolicy, "enforced", false)
    is_enforced == false
}

result := "skip" {
    not is_target_constraint
} else := "fail" {
    fail_policy_not_enforced
}

# --- Metadata ---
currentConfiguration := "Omni Constraint is NOT enforced (Usage Allowed)" {
    fail_policy_not_enforced
} else := "Omni Constraint is enforced (Usage Disabled)"

expectedConfiguration := "BigQuery Omni Organization Policies (AWS/Azure) must be enforced to disable unauthorized usage."
package wiz

# --- Configuration ---
# Allowlist: Define authorized IAM entities for Data Policies.
# Include users, service accounts, groups, and domains.
authorized_iam_members := {
    "user:admin@example.com",
    "group:data-scientists@example.com",
    "serviceAccount:masked-reader@my-project.iam.gserviceaccount.com",
    "domain:example.com" # Be careful with broad domain grants!
}

# --- Logic ---
default result := "pass"

is_data_policy { input.type == "google_bigquery_datapolicy_data_policy" }

# 1. Iterate through IAM Bindings
# We check every member in every role binding.
fail_unauthorized_member {
    is_data_policy
    
    # Navigate safely to bindings
    bindings := object.get(input.properties.iamPolicy, "bindings", [])
    
    # Iterate bindings and members
    binding := bindings[_]
    member := binding.members[_]
    
    # Check if member is in the allowlist
    not authorized_iam_members[member]
}

result := "skip" {
    not is_data_policy
} else := "fail" {
    fail_unauthorized_member
}

# --- Metadata ---
# Helper to capture the unauthorized member for the error message
unauthorized_member_msg := member {
    is_data_policy
    bindings := input.properties.iamPolicy.bindings[_]
    member := bindings.members[_]
    not authorized_iam_members[member]
}

currentConfiguration := sprintf("Data Policy contains unauthorized IAM member: '%v'", [unauthorized_member_msg]) {
    fail_unauthorized_member
} else := "Data Policy IAM is authorized"

expectedConfiguration := sprintf("IAM members on BigQuery Data Policies must match the allowlist: %v", [authorized_iam_members])
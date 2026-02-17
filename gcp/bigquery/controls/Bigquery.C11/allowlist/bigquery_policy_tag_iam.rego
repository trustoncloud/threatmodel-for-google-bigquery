package wiz

# --- Configuration ---
# Allowlist: Define the exact set of authorized entities for Sensitive Policy Tags.
# Keys must match the format: "prefix:value"
authorized_entities := {
    "group:sensitive-data-readers@example.com",
    "user:ciso@example.com",
    "serviceAccount:etl-pipeline@project-id.iam.gserviceaccount.com"
}

# --- Logic ---
default result := "pass"

# Filter for Data Catalog Policy Tags
# Note: Ensure Wiz is configured to ingest 'google_datacatalog_policy_tag'
is_policy_tag {
    input.type == "google_datacatalog_policy_tag"
}

bindings := input.properties.iamPolicy.bindings

# Helper to normalize IAM members
get_member(member) := val {
    val := member # GCP IAM members usually come with prefixes (user:, group:, etc.)
}

# Identify unauthorized entities
# We check ALL roles because any permission on the Policy Tag is a potential risk
unauthorized_findings[member] {
    is_policy_tag
    binding := bindings[_]
    member := binding.members[_]
    not authorized_entities[member]
}

result := "skip" {
    not is_policy_tag
} else := "skip" {
    not input.properties.iamPolicy
} else := "fail" {
    count(unauthorized_findings) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Unauthorized entities found on Policy Tag IAM: %v", [unauthorized_findings]) {
    result == "fail"
} else := "All Policy Tag IAM entities are authorized"

expectedConfiguration := "Only authorized IAM entities must have access to Data Catalog Policy Tags (sensitive columns)."
package wiz

# --- Configuration ---
# 1. Authorized Subscriber Domains
# Users with the 'subscriber' role MUST belong to these domains.
# Example: "yourcompany.com"
authorized_subscriber_domains := {
    "yourcompany.com",
    "partner-domain.com"
}

# 2. Block Public Access?
# If true, strictly blocks 'allUsers' and 'allAuthenticatedUsers'.
block_public_access := true

# --- Logic ---
default result := "pass"

# Target Resources: Data Exchanges AND Listings
is_analytics_hub_resource {
    input.type == "google_bigquery_analytics_hub_data_exchange"
}
is_analytics_hub_resource {
    input.type == "google_bigquery_analytics_hub_listing"
}

# Helper: Get IAM Bindings
# (Adjust path based on how Wiz presents IAM for these resources. 
# Commonly found in 'iamPolicy' or 'bindings')
get_bindings = bindings {
    bindings := object.get(input.properties, "iamPolicy", {}).bindings
} else = [] {
    true
}

# Role to audit: Subscriber
subscriber_roles := {
    "roles/analyticshub.subscriber",
    "roles/analyticshub.admin" # Admins can also subscribe
}

# Helper: Check if a member is authorized
is_member_authorized(member) {
    # Check for Public users
    block_public_access
    member == "allUsers"
    false
} else {
    block_public_access
    member == "allAuthenticatedUsers"
    false
} else {
    # Check Domain Allowlist
    # Logic: Member string usually looks like "user:alice@yourcompany.com"
    # We split by '@' to check the domain.
    parts := split(member, "@")
    count(parts) == 2
    domain := parts[1]
    authorized_subscriber_domains[domain]
} else {
    # Allow specific service accounts or groups if needed (by exact match logic)
    false
}

# Failure: Find unauthorized members in subscriber roles
fail_unauthorized_subscriber[msg] {
    is_analytics_hub_resource
    bindings := get_bindings
    
    # Iterate Bindings
    binding := bindings[_]
    subscriber_roles[binding.role]
    
    # Iterate Members
    member := binding.members[_]
    
    # Check Authorization
    not is_member_authorized(member)
    
    msg := sprintf("Unauthorized subscriber found: '%v' has role '%v'", [member, binding.role])
}

# --- Aggregation ---
result := "skip" {
    not is_analytics_hub_resource
} else := "fail" {
    count(fail_unauthorized_subscriber) > 0
}

# --- Metadata ---
currentConfiguration := concat("; ", fail_unauthorized_subscriber) {
    result == "fail"
} else := "All subscribers are authorized"

expectedConfiguration := "Only authorized domains may hold the 'analyticshub.subscriber' role."
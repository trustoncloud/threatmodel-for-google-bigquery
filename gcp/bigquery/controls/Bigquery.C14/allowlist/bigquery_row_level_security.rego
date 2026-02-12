package wiz

# --- Configuration ---
# 1. Authorized Domains for Row Access
# Users/Groups in Row Access Policies must belong to these domains.
authorized_domains := {
    "yourcompany.com",
    "subsidiary.com",
    "gserviceaccount.com" # Allow service accounts for automated jobs
}

# --- Logic ---
default result := "pass"

# Target: BigQuery Row Access Policy
# Note: Wiz typically maps "bigquery.googleapis.com/RowAccessPolicy" to this type.
is_row_access_policy {
    input.type == "google_bigquery_row_access_policy"
}

# Helper: Get Grantees
# Grantees are the list of IAM principals (user:..., group:..., serviceAccount:...)
# allowed to see the rows defined by the filter.
get_grantees = grantees {
    grantees := object.get(input.properties, "grantees", [])
}

# Helper: Extract Email/Domain from a grantee string
# Format is usually "type:email" (e.g., "user:alice@example.com")
get_grantee_email(grantee_str) = email {
    parts := split(grantee_str, ":")
    count(parts) > 1
    email := parts[1]
} else = grantee_str {
    # Fallback if no prefix exists (unlikely but possible in some API versions)
    true
}

# Failure: Unauthorized Grantee Found
fail_unauthorized_grantee[msg] {
    is_row_access_policy
    grantees := get_grantees
    
    # Iterate through all grantees in the policy
    grantee := grantees[_]
    email := get_grantee_email(grantee)
    
    # Check if the email ends with ANY authorized domain
    # Logic: allowed set must not be empty
    allowed := { d | d := authorized_domains[_]; endswith(email, d) }
    count(allowed) == 0
    
    msg := sprintf("Unauthorized Grantee '%v' found in Row Access Policy", [grantee])
}

# --- Aggregation ---
result := "skip" {
    not is_row_access_policy
} else := "fail" {
    count(fail_unauthorized_grantee) > 0
}

# --- Metadata ---
currentConfiguration := concat("; ", fail_unauthorized_grantee) {
    result == "fail"
} else := "All Row Access Policy grantees are authorized"

expectedConfiguration := "Row Access Policies must only grant access to authorized domains."
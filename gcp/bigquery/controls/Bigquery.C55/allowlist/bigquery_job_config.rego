package wiz

# --- Configuration ---
# 1. Authorized Job Runners (Allowlist)
# Jobs submitted by these emails are EXEMPT from checks.
authorized_job_runners := {
    "etl-prod@my-project.iam.gserviceaccount.com",
    "data-science-lead@my-company.com"
}

# 2. Safety Baselines (Same as Universal)
require_query_byte_limit := true
require_strict_load_schema := true

# --- Logic ---
default result := "pass"

is_job { input.type == "google_bigquery_job" }

# Helper: Get Job Type
get_job_type = "QUERY" { object.get(input.properties.configuration, "query", null) != null }
else = "LOAD" { object.get(input.properties.configuration, "load", null) != null }
else = "UNKNOWN" { true }

# Helper: Check if User is Authorized
is_authorized_user {
    # 'user_email' is usually found in jobReference or user_email field depending on audit logs vs resource
    # Assuming 'user_email' is available in the properties
    email := object.get(input.properties, "user_email", "")
    authorized_job_runners[email]
}

# --- Check 1: Query Safety (With Exception) ---
fail_query_dos_risk {
    is_job
    get_job_type == "QUERY"
    require_query_byte_limit
    
    # EXEMPTION: Skip if user is authorized
    not is_authorized_user
    
    # Check Limit
    config := input.properties.configuration.query
    limit := object.get(config, "maximumBytesBilled", "0")
    limit == "0"
}

# --- Check 2: Load Integrity (With Exception) ---
fail_load_integrity_risk {
    is_job
    get_job_type == "LOAD"
    require_strict_load_schema
    
    # EXEMPTION: Skip if user is authorized
    not is_authorized_user
    
    config := input.properties.configuration.load
    object.get(config, "ignoreUnknownValues", false) == true
}

# --- Aggregation ---
result := "skip" {
    not is_job
} else := "fail" {
    fail_query_dos_risk
} else := "fail" {
    fail_load_integrity_risk
}

# --- Metadata ---
currentConfiguration := "Unauthorized job configuration detected (User is not exempt)" {
    result == "fail"
} else := "Job configuration is authorized or exempt"

expectedConfiguration := "Jobs must have safety limits unless submitted by an authorized service account."
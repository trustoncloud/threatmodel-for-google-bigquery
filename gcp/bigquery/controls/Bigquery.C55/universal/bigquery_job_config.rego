package wiz

# --- Configuration ---
# 1. Availability (Anti-DoS)
# Require queries to have a 'maximumBytesBilled' limit set.
require_query_byte_limit := true

# 2. Data Integrity (Load Jobs)
# If true, load jobs must NOT ignore unknown values (strict schema enforcement).
require_strict_load_schema := true

# --- Logic ---
default result := "pass"

is_job { input.type == "google_bigquery_job" }

# Helper: Determine Job Type
get_job_type = "QUERY" { object.get(input.properties.configuration, "query", null) != null }
else = "LOAD" { object.get(input.properties.configuration, "load", null) != null }
else = "UNKNOWN" { true }

# --- Check 1: Query Safety (Anti-DoS) ---
# Overlaps with C77, but C55 is the broader "Job" control.
fail_query_dos_risk {
    is_job
    get_job_type == "QUERY"
    require_query_byte_limit
    
    # Check if maximumBytesBilled is missing or 0 (unlimited)
    config := input.properties.configuration.query
    limit := object.get(config, "maximumBytesBilled", "0")
    limit == "0"
}

# --- Check 2: Load Integrity (Strict Schema) ---
# Unique to C55 (Not covered by other controls)
fail_load_integrity_risk {
    is_job
    get_job_type == "LOAD"
    require_strict_load_schema
    
    # Check if ignoreUnknownValues is true (Risk: Dropping data silently)
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
currentConfiguration := "Query missing byte limit" {
    fail_query_dos_risk
} else := "Load job ignores unknown values" {
    fail_load_integrity_risk
} else := "Job configuration is secure"

expectedConfiguration := "BigQuery Jobs must have authorized configurations (Query Limits, Strict Schema)."
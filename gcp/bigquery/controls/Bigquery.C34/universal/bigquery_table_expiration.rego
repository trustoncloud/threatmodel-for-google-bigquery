package wiz

# --- Configuration ---
# Universal Data Retention Policy
# Security/Compliance Goal: Data Minimization.
# Define the maximum allowed lifetime (in days) for any table.
max_retention_days := 365

# Convert to ms for comparison with BigQuery timestamps (Int64)
max_retention_ms := max_retention_days * 24 * 60 * 60 * 1000

# --- Logic ---
default result := "pass"

is_table { input.type == "google_bigquery_table" }

# Helper: Get Timestamps
creation_time := to_number(object.get(input.properties, "creationTime", "0"))
expiration_time := to_number(object.get(input.properties, "expirationTime", "0"))

# Helper: Check if Expiration Exists
# If expirationTime is "0" or missing, it means "Never Expire"
has_expiration {
    expiration_time > 0
}

# Calculate actual retention set on the table
actual_retention_ms := expiration_time - creation_time

# Failure 1: No Expiration Set (Infinite Retention)
# A Universal Policy typically mandates that *some* expiration exists.
fail_no_expiration {
    is_table
    not has_expiration
}

# Failure 2: Retention Exceeds Global Limit
fail_excessive_retention {
    is_table
    has_expiration
    
    # Check if the configured duration is longer than the policy allows
    actual_retention_ms > max_retention_ms
}

# --- Aggregation ---
result := "skip" {
    not is_table
} else := "fail" {
    fail_no_expiration
} else := "fail" {
    fail_excessive_retention
}

# --- Metadata ---
currentConfiguration := "Table has no expiration time set (Infinite Retention)" {
    fail_no_expiration
} else := sprintf("Table retention is set to %v days (Limit: %v days)", [round(actual_retention_ms / 86400000), max_retention_days]) {
    fail_excessive_retention
} else := "Table expiration is within global limits"

expectedConfiguration := sprintf("All BigQuery tables must expire within %v days of creation.", [max_retention_days])
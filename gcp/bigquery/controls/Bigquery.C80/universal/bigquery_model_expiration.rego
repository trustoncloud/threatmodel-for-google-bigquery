package wiz

# --- Configuration ---
# Universal ML Governance Policy
# Security Goal: Model Lifecycle Management & Data Minimization.
# Define the maximum allowed lifetime (in days) for any ML model.
max_retention_days := 365

# --- Logic ---
default result := "pass"

is_model { input.type == "google_bigquery_model" }

# Helper: Get Timestamps (Strings in API, convert to numbers)
# "expirationTime" being "0" or missing implies "Never Expire"
get_expiration_ts = val {
    val := to_number(object.get(input.properties, "expirationTime", "0"))
}

get_creation_ts = val {
    val := to_number(object.get(input.properties, "creationTime", "0"))
}

# Calculate limit in milliseconds
max_retention_ms := max_retention_days * 24 * 60 * 60 * 1000

# Failure 1: No Expiration Set (Indefinite Retention)
fail_no_expiration {
    is_model
    exp := get_expiration_ts
    exp == 0
}

# Failure 2: Expiration exceeds allowed limit
fail_excessive_retention {
    is_model
    exp := get_expiration_ts
    create := get_creation_ts
    
    # Ensure expiration is set before calculating
    exp > 0
    
    lifespan := exp - create
    lifespan > max_retention_ms
}

# --- Aggregation ---
result := "skip" {
    not is_model
} else := "fail" {
    fail_no_expiration
} else := "fail" {
    fail_excessive_retention
}

# --- Metadata ---
current_lifespan_days := (get_expiration_ts - get_creation_ts) / 86400000

currentConfiguration := "Model is set to never expire" {
    fail_no_expiration
} else := sprintf("Model lifespan is set to %v days (Limit: %v days)", [round(current_lifespan_days), max_retention_days]) {
    fail_excessive_retention
} else := "Model expiration is within global limits"

expectedConfiguration := sprintf("All BigQuery ML Models must expire within %v days of creation.", [max_retention_days])
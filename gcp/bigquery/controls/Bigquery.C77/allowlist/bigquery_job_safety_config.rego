package wiz

# --- Configuration ---
# 1. Authorized Write Modes
# We strictly allow APPEND and EMPTY. We BLOCK "WRITE_TRUNCATE".
allowed_write_dispositions := {
    "WRITE_APPEND",
    "WRITE_EMPTY"
    # "WRITE_TRUNCATE" <-- Intentionally excluded (Destructive)
}

# 2. Allow Schema Updates?
# Set to false to prevent jobs from modifying table schemas (Schema Drift).
allow_schema_updates := false

# --- Logic ---
default result := "pass"

is_job { input.type == "google_bigquery_job" }

# Helper to get the query config
query_config := object.get(input.properties.configuration, "query", {})

# 1. Check Write Disposition (Destructive Action Check)
fail_destructive_write {
    is_job
    # Get the disposition (Default is WRITE_EMPTY if not set)
    disposition := object.get(query_config, "writeDisposition", "WRITE_EMPTY")
    
    # Fail if the disposition is not in our allowlist
    not allowed_write_dispositions[disposition]
}

# 2. Check Schema Update Options (Integrity Check)
fail_schema_drift {
    is_job
    allow_schema_updates == false
    
    # schemaUpdateOptions is a list of strings (e.g., ["ALLOW_FIELD_ADDITION"])
    options := object.get(query_config, "schemaUpdateOptions", [])
    
    # Fail if the list is not empty (meaning an update option was requested)
    count(options) > 0
}

# --- Aggregation ---
result := "skip" {
    not is_job
} else := "fail" {
    fail_destructive_write
} else := "fail" {
    fail_schema_drift
}

# --- Metadata ---
# Capture the specific destructive setting for the error message
current_write := object.get(query_config, "writeDisposition", "WRITE_EMPTY")
current_schema := object.get(query_config, "schemaUpdateOptions", [])

currentConfiguration := sprintf("Job uses destructive/unauthorized config: Write='%v', SchemaOpts='%v'", [current_write, current_schema]) {
    result == "fail"
} else := "Job configuration is safe"

expectedConfiguration := "Job must use safe WriteDisposition (No Truncate) and SchemaUpdateOptions must be empty."
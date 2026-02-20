package wiz

# --- Configuration ---
allowed_uris := {
    "gs://my-corp-data-lake",
    "gs://partner-upload-bucket",
    "https://drive.google.com"
}

# --- Logic ---
default result := "pass"

is_table { input.type == "google_bigquery_table" }
is_job   { input.type == "google_bigquery_job" }

# 2. Logic for Tables (External Data Sources)
fail_table_source {
    is_table
    uris := input.properties.externalDataConfiguration.sourceUris
    uri := uris[_]
    not starts_with_allowed(uri)
}

# 3. Logic for Jobs (Load & Extract)
fail_job_flow {
    is_job
    
    # SAFE LOOKUP: Get the config block first
    config := input.properties.configuration
    
    # Safe retrieval of nested objects (default to empty object if missing)
    load_block := object.get(config, "load", {})
    extract_block := object.get(config, "extract", {})

    # Now get the URI lists (default to empty list if missing)
    load_uris := object.get(load_block, "sourceUris", [])
    extract_uris := object.get(extract_block, "destinationUris", [])
    
    # Combine and check
    all_uris := array.concat(load_uris, extract_uris)
    uri := all_uris[_]
    not starts_with_allowed(uri)
}

# --- Helper Function ---
starts_with_allowed(uri) {
    allowed := allowed_uris[_]
    startswith(uri, allowed)
}

# --- Result Aggregation ---
result := "skip" {
    not is_table
    not is_job
} else := "fail" {
    fail_table_source
} else := "fail" {
    fail_job_flow
}

# --- Metadata ---
currentConfiguration := "Resource references unauthorized external URIs (Source/Destination)" {
    result == "fail"
} else := "Resource data flow is authorized"

expectedConfiguration := sprintf("BigQuery sources and destinations must match the allowlist: %v", [allowed_uris])
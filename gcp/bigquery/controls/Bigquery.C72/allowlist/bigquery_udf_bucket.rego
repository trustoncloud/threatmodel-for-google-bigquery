package wiz

# --- Configuration ---
# List of trusted GCS bucket prefixes that can host User Defined Functions (UDFs).
# Code loaded from these locations is considered safe.
allowed_udf_buckets := {
    "gs://my-corp-trusted-scripts",
    "gs://partner-lib-bucket/v1/"
}

# --- Logic ---
default result := "pass"

is_job { input.type == "google_bigquery_job" }

# Helper: Retrieve UDF resources safely
# userDefinedFunctionResources is an array of objects: [{resourceUri: "..."}, {inlineCode: "..."}]
udf_resources := object.get(input.properties.configuration.query, "userDefinedFunctionResources", [])

# Check for unauthorized URIs
fail_unauthorized_udf_bucket {
    is_job
    
    # Iterate through each resource in the list
    resource := udf_resources[_]
    
    # Extract the URI (if it exists). 
    # Note: If it's "inlineCode", resourceUri will be missing/null. We skip those.
    uri := object.get(resource, "resourceUri", "")
    uri != ""
    
    # Check if this specific URI matches our allowlist
    not is_allowed_bucket(uri)
}

# Helper: Returns true if uri matches ANY allowed prefix
is_allowed_bucket(uri) {
    allowed := allowed_udf_buckets[_]
    startswith(uri, allowed)
}

# --- Aggregation ---
result := "skip" {
    not is_job
} else := "fail" {
    fail_unauthorized_udf_bucket
}

# --- Metadata ---
# Capture the offending URI for the error message
bad_uri := uri {
    resource := udf_resources[_]
    uri := object.get(resource, "resourceUri", "")
    uri != ""
    not is_allowed_bucket(uri)
}

currentConfiguration := sprintf("Job references unauthorized UDF source: '%v'", [bad_uri]) {
    fail_unauthorized_udf_bucket
} else := "UDF sources are authorized"

expectedConfiguration := sprintf("BigQuery UDFs must be loaded from authorized GCS buckets: %v", [allowed_udf_buckets])
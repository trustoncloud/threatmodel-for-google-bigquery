package wiz

# --- NOTE ON IMPLEMENTATION ---
# BigQuery ML Models do not have a native "fingerprint" API field. 
# We utilize Labels to "embed" the security fingerprint (e.g., a SHA-256 hash).
# This allows security teams to verify model provenance and integrity.

# --- Configuration ---
# 1. The Label Key acting as the "Fingerprint"
required_fingerprint_key := "security_fingerprint"

# 2. Valid Format (Regex)
# Example: SHA-256 Hash (64 hex characters)
fingerprint_regex := "^[a-f0-9]{64}$"

# --- Logic ---
default result := "pass"

is_model { input.type == "google_bigquery_model" }

# Helper: Get Labels safely
labels := object.get(input.properties, "labels", {})

# 1. Check if Fingerprint Label is Missing
fail_missing_fingerprint {
    is_model
    # Idiomatic check: "not labels[key]" returns true if key is missing
    not labels[required_fingerprint_key]
}

# 2. Check Fingerprint Format (Integrity Check)
fail_invalid_fingerprint_format {
    is_model
    # Retrieve the value directly now that we know it exists (or check implicitly)
    val := labels[required_fingerprint_key]
    
    # Check regex
    not regex.match(fingerprint_regex, val)
}

# --- Aggregation ---
result := "skip" {
    not is_model
} else := "fail" {
    fail_missing_fingerprint
} else := "fail" {
    fail_invalid_fingerprint_format
}

# --- Metadata ---
current_val := object.get(labels, required_fingerprint_key, "MISSING")

currentConfiguration := sprintf("Model Fingerprint Label '%v' is: %v", [required_fingerprint_key, current_val]) {
    result == "fail"
} else := "Model Fingerprint is present and valid"

expectedConfiguration := sprintf("ML Models must have a '%v' label matching regex '%v'.", [required_fingerprint_key, fingerprint_regex])
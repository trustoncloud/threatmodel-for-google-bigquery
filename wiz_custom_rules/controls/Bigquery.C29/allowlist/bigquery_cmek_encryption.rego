package wiz

# --- Configuration ---
# Allowlist: Define authorized keys.
# Strategy A: Authorize the KEY (Allows this key and ALL its versions)
# Strategy B: Authorize a VERSION (Strictly allows ONLY this version)
authorized_keys := {
    # Strategy A: Any version of 'finance-key' is allowed
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key",
    
    # Strategy B: ONLY Version 5 of 'hr-key' is allowed (Strict Pinning)
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key/cryptoKeyVersions/5"
}

# --- Logic ---
default result := "pass"

is_dataset { input.type == "google_bigquery_dataset" }
is_table   { input.type == "google_bigquery_table" }

# 1. Extract the Key Name used by the resource
key_name := input.properties.defaultEncryptionConfiguration.kmsKeyName { is_dataset }
key_name := input.properties.encryptionConfiguration.kmsKeyName { is_table }

# 2. Check Authorization (Prefix Match)
# This allows the resource to be more specific than the allowlist, but not different.
is_authorized {
    # Iterate through our allowed list
    allowed := authorized_keys[_]
    # CHECK: Does the resource key START with the allowed string?
    startswith(key_name, allowed)
}

# --- Fail Conditions ---
fail_no_cmek {
    not key_name
}

fail_unauthorized_key {
    key_name
    not is_authorized
}

result := "skip" {
    not is_dataset
    not is_table
} else := "fail" {
    fail_no_cmek
} else := "fail" {
    fail_unauthorized_key
}

# --- Metadata ---
currentConfiguration := "Resource is using Google-Managed Encryption (No CMEK)" {
    fail_no_cmek
} else := sprintf("Resource is encrypted with key/version: '%v'", [key_name]) {
    # Capture the exact version used in the output for audit purposes
    result != "skip"
}

expectedConfiguration := "BigQuery resources must use an authorized CMEK (Key or Specific Version)."
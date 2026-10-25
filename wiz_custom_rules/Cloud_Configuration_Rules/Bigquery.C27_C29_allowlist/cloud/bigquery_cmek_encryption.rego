package wiz

# --- Configuration ---
# Allowlist: Define authorized keys.
# Strategy A: Authorize the KEY (Allows this key and ALL its versions)
# Strategy B: Authorize a VERSION (Strictly allows ONLY this version)
authorized_kms_keys := {
    # Strategy A: Any version of 'finance-key' is allowed
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key",

    # Strategy B: ONLY Version 5 of 'hr-key' is allowed (Strict Pinning)
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key/cryptoKeyVersions/5"
}

# --- Logic ---
default result := "pass"

# Routed types: datasets carry defaultEncryptionConfiguration; tables and
# models carry encryptionConfiguration. The config block is absent when the
# resource uses Google-managed encryption.
is_supported_resource {
    input.datasetReference
}
is_supported_resource {
    input.tableReference
}
is_supported_resource {
    input.modelReference
}

# 1. Extract the Key Name used by the resource
key_name := val {
    val := input.defaultEncryptionConfiguration.kmsKeyName
    val != ""
}
key_name := val {
    val := input.encryptionConfiguration.kmsKeyName
    val != ""
}

# 2. Check Authorization (Prefix Match)
# This allows the resource to be more specific than the allowlist, but not different.
is_authorized {
    allowed := authorized_kms_keys[_]
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
    not is_supported_resource
} else := "fail" {
    fail_no_cmek
} else := "fail" {
    fail_unauthorized_key
}

# --- Metadata ---
currentConfiguration := "Resource is using Google-Managed Encryption (No CMEK)" {
    fail_no_cmek
} else := sprintf("Resource is encrypted with key/version: '%v'", [key_name]) {
    result != "skip"
}

expectedConfiguration := "BigQuery resources must use an authorized CMEK (Key or Specific Version)."

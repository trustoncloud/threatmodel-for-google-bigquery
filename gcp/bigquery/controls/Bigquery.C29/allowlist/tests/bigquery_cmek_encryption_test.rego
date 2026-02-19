package wiz

# --- SCENARIO 1: KEY-LEVEL AUTHORIZATION ---
# Allowlist has: ".../finance-key"
# Input has:     ".../finance-key/cryptoKeyVersions/1"
# Result:        PASS (Because input starts with allowed key)

test_pass_versioned_child {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "table-pinned-version",
        "properties": {
            "encryptionConfiguration": {
                # This is a specific version of the allowed key
                "kmsKeyName": "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key/cryptoKeyVersions/1"
            }
        }
    }
}

test_pass_exact_key {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "table-auto-rotate",
        "properties": {
            "encryptionConfiguration": {
                # Exact match of the key root
                "kmsKeyName": "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
            }
        }
    }
}

# --- SCENARIO 2: VERSION-LEVEL AUTHORIZATION (STRICT) ---
# Allowlist has: ".../hr-key/cryptoKeyVersions/5"

test_pass_exact_version {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "table-correct-version",
        "properties": {
            "encryptionConfiguration": {
                "kmsKeyName": "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key/cryptoKeyVersions/5"
            }
        }
    }
}

test_fail_wrong_version {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "table-wrong-version",
        "properties": {
            "encryptionConfiguration": {
                # Version 6 is NOT authorized (only 5 is)
                "kmsKeyName": "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key/cryptoKeyVersions/6"
            }
        }
    }
}

test_fail_key_root_too_broad {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "table-too-broad",
        "properties": {
            "encryptionConfiguration": {
                # Input is just the Key, but Allowlist required Version 5.
                # Key Root does NOT start with ".../Version/5", so it fails.
                "kmsKeyName": "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key"
            }
        }
    }
}
package wiz

# --- TEST 1: DATASETS ---

# PASS: Has CMEK (Any key is fine)
test_universal_pass_dataset {
    result == "pass" with input as {
        "type": "google_bigquery_dataset",
        "name": "encrypted-ds",
        "properties": {
            "defaultEncryptionConfiguration": {
                "kmsKeyName": "projects/p/locations/l/keyRings/r/cryptoKeys/k"
            }
        }
    }
}

# FAIL: Missing config (Google Managed)
test_universal_fail_dataset {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "unencrypted-ds",
        "properties": {
            # No encryption config
        }
    }
}

# --- TEST 2: TABLES ---

# PASS: Has CMEK
test_universal_pass_table {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "encrypted-table",
        "properties": {
            "encryptionConfiguration": {
                "kmsKeyName": "projects/p/locations/l/keyRings/r/cryptoKeys/k"
            }
        }
    }
}

# FAIL: Missing config
test_universal_fail_table {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "unencrypted-table",
        "properties": {
            # No encryption config
        }
    }
}
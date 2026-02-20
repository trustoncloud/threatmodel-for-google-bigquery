package wiz

# --- TEST 1: PASS - Valid Fingerprint ---
test_pass_valid {
    result == "pass" with input as {
        "type": "google_bigquery_model",
        "name": "governed-model",
        "properties": {
            "labels": {
                # Valid SHA-256 Hex string
                "security_fingerprint": "a1b2c3d4e5f60718293041526374859607182930415263748596a1b2c3d4e5f6"
            }
        }
    }
}

# --- TEST 2: FAIL - Missing Fingerprint Label ---
test_fail_missing {
    result == "fail" with input as {
        "type": "google_bigquery_model",
        "name": "rogue-model",
        "properties": {
            "labels": {
                "owner": "data-science" # Fingerprint key is missing
            }
        }
    }
}

# --- TEST 3: FAIL - Invalid Format (Tampered/Bad Format) ---
test_fail_format {
    result == "fail" with input as {
        "type": "google_bigquery_model",
        "name": "bad-hash-model",
        "properties": {
            "labels": {
                # Too short / Not a hash
                "security_fingerprint": "pending-approval"
            }
        }
    }
}
package wiz

# --- TEST 1: PASS - Valid Configuration (Within 30m - 7d) ---
test_pass_valid {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "valid-table",
        "properties": {
            "maxStaleness": "3600s", # 1 hour
            "externalDataConfiguration": { "metadataCacheMode": "AUTOMATIC" }
        }
    }
}

# --- TEST 2: PASS - Cache Not Configured (Default/Disabled) ---
# CRITICAL: This ensures we don't flag tables that aren't even using the feature.
test_pass_not_configured {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "standard-external",
        "properties": {
            # maxStaleness might exist, but if cache mode is missing, it's irrelevant
            "maxStaleness": "0s", 
            "externalDataConfiguration": {
                # metadataCacheMode is MISSING here
                "sourceUris": ["gs://bucket/file.csv"]
            }
        }
    }
}

# --- TEST 3: FAIL - Too Short (< 30 mins) ---
test_fail_too_short {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "fast-table",
        "properties": {
            "maxStaleness": "600s", # 10 mins
            "externalDataConfiguration": { "metadataCacheMode": "AUTOMATIC" }
        }
    }
}

# --- TEST 4: FAIL - Too Long (> 7 days) ---
test_fail_too_long {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "slow-table",
        "properties": {
            "maxStaleness": "2592000s", # 30 days
            "externalDataConfiguration": { "metadataCacheMode": "AUTOMATIC" }
        }
    }
}

# --- TEST 5: FAIL - Invalid Mode ---
test_fail_invalid_mode {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "bad-mode-table",
        "properties": {
            "maxStaleness": "3600s",
            "externalDataConfiguration": { 
                "metadataCacheMode": "ALWAYS_ON" # Not a valid GCP value
            }
        }
    }
}
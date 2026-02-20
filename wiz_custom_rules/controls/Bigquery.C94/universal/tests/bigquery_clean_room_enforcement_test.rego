package wiz

# --- TEST 1: PASS - Valid Data Clean Room ---
# This is the ONLY authorized state in Universal mode.
test_pass_dcr_configured {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/secure-dcr",
        "properties": {
            "sharingEnvironmentConfig": {
                "dcrExchangeConfig": {} # Presence = PASS
            }
        }
    }
}

# --- TEST 2: FAIL - Explicit Standard Exchange ---
# The user explicitly created a standard exchange (defaultExchangeConfig).
# This is strictly prohibited in Universal mode.
test_fail_standard_exchange {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/standard-exchange",
        "properties": {
            "sharingEnvironmentConfig": {
                "defaultExchangeConfig": {} # Explicitly Not DCR = FAIL
            }
        }
    }
}

# --- TEST 3: FAIL - Empty Configuration Object ---
# The config object exists but lacks the DCR field.
test_fail_empty_config_object {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/empty-config",
        "properties": {
            "sharingEnvironmentConfig": {} # Empty = FAIL
        }
    }
}

# --- TEST 4: FAIL - Missing Configuration Block ---
# The sharingEnvironmentConfig block is missing entirely from the resource.
test_fail_missing_environment_block {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/legacy-exchange",
        "properties": {
            # "sharingEnvironmentConfig" is completely missing
            "description": "Legacy exchange created before DCRs"
        }
    }
}

# --- TEST 5: SKIP - Irrelevant Resource ---
# Ensures the logic doesn't accidentally block Datasets or Tables.
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset", # Wrong Type
        "name": "projects/p1/datasets/my-dataset",
        "properties": {
            # Even if it had a similarly named field, it should skip based on type
            "sharingEnvironmentConfig": { "dcrExchangeConfig": {} }
        }
    }
}
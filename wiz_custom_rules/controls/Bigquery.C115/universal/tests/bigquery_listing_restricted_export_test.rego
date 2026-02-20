package wiz

# --- TEST 1: PASS - Fully Secure Listing ---
test_pass_secure {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "projects/p1/listings/secure",
        "properties": {
            "restrictedExportConfig": {
                "enabled": true,
                "restrictQueryResult": true
            }
        }
    }
}

# --- TEST 2: FAIL - Restricted Export Disabled ---
test_fail_disabled {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "projects/p1/listings/open",
        "properties": {
            "restrictedExportConfig": {
                "enabled": false
            }
        }
    }
}

# --- TEST 3: FAIL - Configuration Missing ---
test_fail_missing_config {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "projects/p1/listings/missing",
        "properties": {} # Missing config block entirely
    }
}

# --- TEST 4: FAIL - Query Result Leak ---
test_fail_query_leak {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "projects/p1/listings/leaky",
        "properties": {
            "restrictedExportConfig": {
                "enabled": true,
                "restrictQueryResult": false # Fail
            }
        }
    }
}

# --- TEST 5: SKIP - Wrong Resource ---
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/p1/datasets/d1"
    }
}
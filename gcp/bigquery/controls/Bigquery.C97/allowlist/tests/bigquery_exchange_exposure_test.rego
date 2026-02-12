package wiz

# --- TEST 1: PASS - Valid Private Exchange ---
test_pass_private {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/internal-exchange",
        "properties": {
            "discoveryType": "PRIVATE" # Allowed by default
        }
    }
}

# --- TEST 2: FAIL - Unauthorized Public Exchange ---
test_fail_rogue_public {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/rogue-public",
        "properties": {
            "discoveryType": "PUBLIC" # Not in allowlist, not in exception list
        }
    }
}

# --- TEST 3: PASS - Authorized Public Exchange (Exception) ---
test_pass_authorized_public {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/my-org/locations/us/dataExchanges/official-public-dataset",
        "properties": {
            "discoveryType": "PUBLIC" # In authorized_public_exchanges
        }
    }
}

# --- TEST 4: FAIL - Unknown/Unspecified Type ---
test_fail_unspecified {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/p1/locations/us/dataExchanges/broken-config",
        "properties": {
            # Missing discoveryType or set to UNSPECIFIED
            "discoveryType": "DISCOVERY_TYPE_UNSPECIFIED"
        }
    }
}
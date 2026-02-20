package wiz

# TEST 1: PASS - Private Exchange
test_pass_private {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "properties": { "discoveryType": "PRIVATE" }
    }
}

# TEST 2: FAIL - Public Exchange
test_fail_public {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "properties": { "discoveryType": "PUBLIC" }
    }
}

# TEST 3: FAIL - Unspecified Type
test_fail_unspecified {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "properties": { "discoveryType": "DISCOVERY_TYPE_UNSPECIFIED" }
    }
}
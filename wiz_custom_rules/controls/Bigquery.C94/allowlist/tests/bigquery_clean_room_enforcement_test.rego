package wiz

# --- TEST 1: PASS - Required Exchange correctly configured as DCR ---
test_pass_valid_dcr {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/prod-data-sharing/locations/us/dataExchanges/sensitive_partner_exchange",
        "properties": {
            "sharingEnvironmentConfig": {
                # Corrected Field Name
                "dcrExchangeConfig": {} 
            }
        }
    }
}

# --- TEST 2: FAIL - Required Exchange configured as Standard ---
test_fail_standard_instead_of_dcr {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/marketing-analytics/locations/us/dataExchanges/pii_clean_room",
        "properties": {
            "sharingEnvironmentConfig": {
                # Missing dcrExchangeConfig (e.g., has defaultExchangeConfig or empty)
                "defaultExchangeConfig": {}
            }
        }
    }
}

# --- TEST 3: PASS - Standard Exchange (Not in required list) ---
test_pass_not_required {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/public-data/locations/us/dataExchanges/free_weather_data",
        "properties": {
            "sharingEnvironmentConfig": {
                "defaultExchangeConfig": {}
            }
        }
    }
}

# --- TEST 4: PASS - Optional DCR ---
test_pass_optional_dcr {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "projects/dev/locations/us/dataExchanges/experimental_dcr",
        "properties": {
            "sharingEnvironmentConfig": {
                "dcrExchangeConfig": {} 
            }
        }
    }
}
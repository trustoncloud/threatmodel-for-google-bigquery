package wiz

# --- TEST 1: PASS - Clean Listing ---
test_pass_clean {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "clean-listing",
        "properties": {
            "displayName": "Public Holiday Data",
            "description": "Contains list of holidays.",
            "documentation": "https://wiki.company.com/holidays"
        }
    }
}

# --- TEST 2: FAIL - Leaked API Key in Description ---
test_fail_api_key {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "leaky-listing-1",
        "properties": {
            "displayName": "Test Data",
            # Adjusted to be exactly 39 characters (4 + 35) to match the regex
            "description": "Use this key: AIzaSyD-ExampleKey1234567890123456789AB"
        }
    }
}

# --- TEST 3: FAIL - PII (Email) in Documentation ---
test_fail_email_leak {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "leaky-listing-2",
        "properties": {
            "displayName": "Contact List",
            "description": "Reach out to us.",
            # Matches Email regex
            "documentation": "Contact admin@secret-internal.com for access."
        }
    }
}

# --- TEST 4: FAIL - Password Keyword ---
test_fail_password {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "leaky-listing-3",
        "properties": {
            # Matches "password = ..." regex
            "description": "Default password = Changeme123"
        }
    }
}
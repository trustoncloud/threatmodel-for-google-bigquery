package wiz

# --- TEST 1: PASS - Authorized Internal Subscribers ---
test_pass_internal {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "internal-exchange",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/analyticshub.subscriber",
                        "members": ["user:alice@yourcompany.com", "group:analysts@yourcompany.com"]
                    }
                ]
            }
        }
    }
}

# --- TEST 2: FAIL - Unauthorized Domain (Gmail) ---
test_fail_gmail {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "leaky-listing",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/analyticshub.subscriber",
                        "members": ["user:hacker@gmail.com"] # Unauthorized Domain
                    }
                ]
            }
        }
    }
}

# --- TEST 3: FAIL - Public Access (allUsers) ---
test_fail_public {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "public-listing",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/analyticshub.subscriber",
                        "members": ["allUsers"] # Strictly Blocked
                    }
                ]
            }
        }
    }
}

# --- TEST 4: PASS - Non-Subscriber Roles (Ignored) ---
# Viewers permissions are not part of "Subscription" governance in this control
test_pass_viewer {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "view-only",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/viewer",
                        "members": ["allUsers"] # This control ignores generic viewer roles
                    }
                ]
            }
        }
    }
}
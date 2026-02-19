package wiz

# --- TEST 1: PASS - Authorized Grantees ---
test_pass_valid {
    result == "pass" with input as {
        "type": "google_bigquery_row_access_policy",
        "name": "projects/p1/locations/us/instances/i1/rowAccessPolicies/policy_us_data",
        "properties": {
            "filterPredicate": "region = 'US'",
            "grantees": [
                "user:alice@yourcompany.com",
                "group:analysts@subsidiary.com",
                "serviceAccount:etl-job@app.gserviceaccount.com"
            ]
        }
    }
}

# --- TEST 2: FAIL - Unauthorized Domain (Gmail) ---
test_fail_gmail {
    result == "fail" with input as {
        "type": "google_bigquery_row_access_policy",
        "name": "projects/p1/locations/us/instances/i1/rowAccessPolicies/policy_leak",
        "properties": {
            "filterPredicate": "true", # Grant all rows
            "grantees": [
                "user:alice@yourcompany.com",
                "user:hacker@gmail.com" # FAIL
            ]
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Vendor Domain ---
test_fail_vendor {
    result == "fail" with input as {
        "type": "google_bigquery_row_access_policy",
        "name": "projects/p1/locations/us/instances/i1/rowAccessPolicies/policy_vendor",
        "properties": {
            "filterPredicate": "department = 'HR'",
            "grantees": [
                "user:consultant@external-vendor.com" # FAIL: Not in allowlist
            ]
        }
    }
}

# --- TEST 4: SKIP - Not a Row Access Policy ---
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset",
        "name": "dataset1"
    }
}
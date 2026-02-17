package wiz

# 1. PASS: Correct Location and Expiration
test_pass_compliant {
    result == "pass" with input as {
        "name": "compliant-dataset",
        "type": "google_bigquery_dataset",
        "properties": {
            "location": "US",
            "defaultTableExpirationMs": "5184000000"
        }
    }
}

# 2. FAIL: Wrong Location
test_fail_location {
    result == "fail" with input as {
        "name": "bad-loc",
        "type": "google_bigquery_dataset",
        "properties": {
            "location": "EU", # Unauthorized
            "defaultTableExpirationMs": "5184000000"
        }
    }
}

# 3. FAIL: Wrong Expiration (e.g., set to 1 day instead of the required 60 days)
test_fail_expiration {
    result == "fail" with input as {
        "name": "bad-retention",
        "type": "google_bigquery_dataset",
        "properties": {
            "location": "US",
            "defaultTableExpirationMs": "86400000" # Unauthorized value
        }
    }
}

# 4. PASS: Expiration not set (If the intent is only to validate it IF it exists)
# Note: If you want to MANDATE expiration, the Rego logic needs to change to fail on missing property.
test_pass_no_expiration {
    result == "pass" with input as {
        "name": "permanent-dataset",
        "type": "google_bigquery_dataset",
        "properties": {
            "location": "US"
            # defaultTableExpirationMs is missing, so the rule skips that check
        }
    }
}
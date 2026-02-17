package wiz

# 1. PASS: All entities are in the authorized list
test_allowlist_pass_authorized {
    result == "pass" with input as {
        "name": "secure-dataset",
        "type": "google_bigquery_dataset",
        "properties": {
            "access": [
                {"role": "OWNER", "specialGroup": "projectOwners"},
                {"role": "WRITER", "groupByEmail": "data-team@example.com"}
            ]
        }
    }
}

# 2. FAIL: Contains an unauthorized user
test_allowlist_fail_unauthorized_user {
    result == "fail" with input as {
        "name": "compromised-dataset",
        "type": "google_bigquery_dataset",
        "properties": {
            "access": [
                {"role": "OWNER", "specialGroup": "projectOwners"},
                {"role": "READER", "userByEmail": "hacker@evil.com"}
            ]
        }
    }
}

# 3. FAIL: Contains an unauthorized domain
test_allowlist_fail_unauthorized_domain {
    result == "fail" with input as {
        "name": "public-dataset",
        "type": "google_bigquery_dataset",
        "properties": {
            "access": [
                {"role": "READER", "domain": "gmail.com"}
            ]
        }
    }
}

# 4. SKIP: Access list is missing
test_skip_missing_access {
    result == "skip" with input as {
        "name": "empty-dataset",
        "type": "google_bigquery_dataset",
        "properties": {}
    }
}
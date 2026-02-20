package wiz

# --- TEST 1: PASS - Fully Compliant ---
test_pass_compliant {
    result == "pass" with input as {
        "type": "google_bigquery_dataset",
        "name": "compliant_ds",
        "properties": {
            "access": [
                # Mandatory Entity (Present)
                { "role": "OWNER", "groupByEmail": "data-admins@yourcompany.com" },
                # Authorized User
                { "role": "READER", "userByEmail": "analyst@yourcompany.com" },
                # Authorized Service Account (Legacy format)
                { "role": "WRITER", "userByEmail": "etl-job@app.gserviceaccount.com" }
            ]
        }
    }
}

# --- TEST 2: FAIL - Unauthorized Domain (Legacy userByEmail) ---
test_fail_external_user {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "leaky_ds",
        "properties": {
            "access": [
                { "role": "OWNER", "groupByEmail": "data-admins@yourcompany.com" },
                # Unauthorized Domain
                { "role": "READER", "userByEmail": "contractor@external-vendor.com" }
            ]
        }
    }
}

# --- TEST 3: FAIL - Public Access (specialGroup) ---
test_fail_public_access {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "public_ds",
        "properties": {
            "access": [
                { "role": "OWNER", "groupByEmail": "data-admins@yourcompany.com" },
                # Public Block
                { "role": "READER", "specialGroup": "allUsers" }
            ]
        }
    }
}

# --- TEST 4: FAIL - Missing Mandatory Entity (Drift) ---
test_fail_missing_admin {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "rogue_ds",
        "properties": {
            "access": [
                # The mandatory "data-admins" group is missing!
                { "role": "OWNER", "userByEmail": "shadow-it@yourcompany.com" }
            ]
        }
    }
}

# --- TEST 5: FAIL - Unauthorized IAM Member (Parsing Check) ---
# Tests if the regex/parsing logic correctly handles "user:..." strings
test_fail_iam_member_parsing {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "iam_parsing_test",
        "properties": {
            "access": [
                { "role": "OWNER", "groupByEmail": "data-admins@yourcompany.com" },
                # Malicious user added via iamMember syntax
                { "role": "READER", "iamMember": "user:hacker@gmail.com" }
            ]
        }
    }
}

# --- TEST 6: FAIL - Multiple Violations (Aggregation Check) ---
# Ensures that if a dataset has BOTH a missing admin AND a public group, both are detected.
test_fail_multiple_issues {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "disaster_ds",
        "properties": {
            "access": [
                # 1. Missing Admin (Drift) - data-admins is absent
                # 2. Public Access (Security)
                { "role": "READER", "specialGroup": "allUsers" }
            ]
        }
    }
}
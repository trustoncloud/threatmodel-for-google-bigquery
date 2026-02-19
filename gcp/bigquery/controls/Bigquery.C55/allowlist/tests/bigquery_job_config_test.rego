package wiz

# --- TEST 1: PASS - Standard Compliant User ---
# Scenario: An unauthorized user (normal dev) runs a SAFE query.
# Result: PASS because they followed the rules.
test_pass_compliant_user {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/dev_query",
        "properties": {
            "user_email": "developer@my-company.com", # Not in allowlist
            "configuration": {
                "query": {
                    "query": "SELECT * FROM t1",
                    "maximumBytesBilled": "10000000" # Limit Set -> SAFE
                }
            }
        }
    }
}

# --- TEST 2: PASS - Authorized Exception (The "Super User") ---
# Scenario: An AUTHORIZED service account runs a RISKY query (Unlimited).
# Result: PASS because they are exempt from the check.
test_pass_authorized_exception {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/etl_production_job",
        "properties": {
            "user_email": "etl-prod@my-project.iam.gserviceaccount.com", # Authorized!
            "configuration": {
                "query": {
                    "query": "SELECT * FROM huge_table",
                    "maximumBytesBilled": "0" # Risky (Unlimited), but Allowed
                }
            }
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Risk (Query) ---
# Scenario: An unauthorized user tries to run a RISKY query (Unlimited).
# Result: FAIL because they are not exempt and broke the rules.
test_fail_unauthorized_dos {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/rogue_query",
        "properties": {
            "user_email": "intern@my-company.com", # Unauthorized
            "configuration": {
                "query": {
                    "query": "SELECT * FROM huge_table"
                    # maximumBytesBilled MISSING -> FAIL
                }
            }
        }
    }
}

# --- TEST 4: FAIL - Unauthorized Risk (Load) ---
# Scenario: An unauthorized user tries to load data with LOOSE validation.
# Result: FAIL because they are not exempt.
test_fail_unauthorized_integrity {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/bad_import",
        "properties": {
            "user_email": "contractor@external.com", # Unauthorized
            "configuration": {
                "load": {
                    "sourceUris": ["gs://bucket/data.csv"],
                    "ignoreUnknownValues": true # FAIL: Integrity Risk
                }
            }
        }
    }
}

# --- TEST 5: PASS - Authorized Load Exception ---
# Scenario: Authorized account does the same loose load as Test 4.
# Result: PASS because they are exempt.
test_pass_authorized_load {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/legacy_etl_import",
        "properties": {
            "user_email": "data-science-lead@my-company.com", # Authorized!
            "configuration": {
                "load": {
                    "ignoreUnknownValues": true # Allowed for this user
                }
            }
        }
    }
}

# --- TEST 6: SKIP - Wrong Resource ---
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/p1/datasets/d1"
    }
}
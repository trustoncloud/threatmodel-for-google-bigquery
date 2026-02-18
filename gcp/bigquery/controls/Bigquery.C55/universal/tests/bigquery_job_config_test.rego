package wiz

# --- TEST 1: PASS - Secure Query Job ---
# Scenario: A query job that correctly sets a billing limit (Anti-DoS).
test_pass_secure_query {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/daily_report",
        "properties": {
            "configuration": {
                "query": {
                    "query": "SELECT * FROM dataset.table",
                    # Limit is present and not "0" -> PASS
                    "maximumBytesBilled": "10000000000" 
                }
            }
        }
    }
}

# --- TEST 2: PASS - Secure Load Job ---
# Scenario: A load job that enforces strict schema validation (Integrity).
test_pass_secure_load {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/csv_import",
        "properties": {
            "configuration": {
                "load": {
                    "sourceUris": ["gs://bucket/data.csv"],
                    # Default is false, or explicitly false -> PASS
                    "ignoreUnknownValues": false 
                }
            }
        }
    }
}

# --- TEST 3: FAIL - Query DoS Risk (Unlimited Billing) ---
# Scenario: A query job with "maximumBytesBilled" missing.
test_fail_query_missing_limit {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/rogue_analyst_query",
        "properties": {
            "configuration": {
                "query": {
                    "query": "SELECT * FROM huge_table"
                    # maximumBytesBilled is MISSING -> FAIL
                }
            }
        }
    }
}

# --- TEST 4: FAIL - Query DoS Risk (Explicitly Zero) ---
# Scenario: A query job where the limit is explicitly set to "0" (Unlimited).
test_fail_query_zero_limit {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/unlimited_query",
        "properties": {
            "configuration": {
                "query": {
                    "query": "SELECT * FROM huge_table",
                    "maximumBytesBilled": "0" # FAIL
                }
            }
        }
    }
}

# --- TEST 5: FAIL - Load Integrity Risk (Silent Failures) ---
# Scenario: A load job configured to ignore bad data (ignoreUnknownValues = true).
test_fail_load_loose_schema {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/sloppy_import",
        "properties": {
            "configuration": {
                "load": {
                    "sourceUris": ["gs://bucket/bad_data.csv"],
                    "ignoreUnknownValues": true # FAIL
                }
            }
        }
    }
}

# --- TEST 6: PASS - Extract Job (Out of Scope) ---
# Scenario: An Extract job. Our universal policy focuses on Query/Load risks.
# Extract jobs should generally pass unless we add Denylist logic later.
test_pass_extract_job {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "jobs/data_export",
        "properties": {
            "configuration": {
                "extract": {
                    "sourceUri": "gs://bucket/export.csv"
                }
            }
        }
    }
}

# --- TEST 7: SKIP - Wrong Resource Type ---
# Scenario: Input is a Dataset, not a Job.
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/p1/datasets/d1"
    }
}
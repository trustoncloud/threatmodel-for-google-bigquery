package wiz

# --- TEST 1: PASS - Safe Append Job ---
test_pass_safe_job {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "safe-append",
        "properties": {
            "configuration": {
                "query": {
                    "writeDisposition": "WRITE_APPEND",
                    "schemaUpdateOptions": [] # No schema changes
                }
            }
        }
    }
}

# --- TEST 2: FAIL - Destructive Truncate (Data Wipe) ---
test_fail_truncate {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "dangerous-wipe",
        "properties": {
            "configuration": {
                "query": {
                    "writeDisposition": "WRITE_TRUNCATE", # Not in allowlist
                    "schemaUpdateOptions": []
                }
            }
        }
    }
}

# --- TEST 3: FAIL - Schema Drift (Adding Columns) ---
test_fail_schema_drift {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "schema-changer",
        "properties": {
            "configuration": {
                "query": {
                    "writeDisposition": "WRITE_APPEND",
                    "schemaUpdateOptions": ["ALLOW_FIELD_ADDITION"] # Not allowed
                }
            }
        }
    }
}

# --- TEST 4: PASS - Default Behavior (Missing fields = Safe) ---
test_pass_defaults {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "default-job",
        "properties": {
            "configuration": {
                "query": {
                    # Missing writeDisposition defaults to EMPTY (Allowed)
                    # Missing schemaUpdateOptions defaults to [] (Allowed)
                }
            }
        }
    }
}
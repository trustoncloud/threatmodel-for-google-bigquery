package wiz

# --- TEST 1: PASS - Security Enabled ---
test_pass_secure {
    result == "pass" with input as {
        "type": "google_bigquery_project_service_config",
        "name": "projects/secure-project",
        "properties": {
            "enableFineGrainedDatasetAclsOption": true
        }
    }
}

# --- TEST 2: FAIL - Security Disabled (Explicit) ---
test_fail_disabled {
    result == "fail" with input as {
        "type": "google_bigquery_project_service_config",
        "name": "projects/legacy-project",
        "properties": {
            "enableFineGrainedDatasetAclsOption": false
        }
    }
}

# --- TEST 3: FAIL - Security Disabled (Implicit/Missing) ---
test_fail_missing {
    result == "fail" with input as {
        "type": "google_bigquery_project_service_config",
        "name": "projects/broken-project",
        "properties": {
            # Field missing -> defaults to false -> FAIL
            "otherField": 123
        }
    }
}
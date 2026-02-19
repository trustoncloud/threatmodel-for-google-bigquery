package wiz

# --- TEST 1: PASS - Authorized Members Only ---
test_pass_authorized {
    result == "pass" with input as {
        "type": "google_bigquery_datapolicy_data_policy",
        "name": "pii-masking-policy",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/bigquerydatapolicy.maskedReader",
                        "members": [
                            "group:data-scientists@example.com",
                            "serviceAccount:masked-reader@my-project.iam.gserviceaccount.com"
                        ]
                    }
                ]
            }
        }
    }
}

# --- TEST 2: FAIL - Unauthorized Member (The "Intern") ---
test_fail_unauthorized {
    result == "fail" with input as {
        "type": "google_bigquery_datapolicy_data_policy",
        "name": "sensitive-policy",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/bigquerydatapolicy.maskedReader",
                        "members": [
                            "user:intern@example.com" # Not in allowlist
                        ]
                    }
                ]
            }
        }
    }
}

# --- TEST 3: SKIP - Other Resource ---
test_skip_other {
    result == "skip" with input as {
        "type": "google_bigquery_dataset"
    }
}
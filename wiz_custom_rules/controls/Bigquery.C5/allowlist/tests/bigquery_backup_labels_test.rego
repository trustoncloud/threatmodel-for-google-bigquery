package wiz

# 1. PASS: Dataset labeled for daily backup
test_pass_daily_backup {
    result == "pass" with input as {
        "name": "prod-data",
        "type": "google_bigquery_dataset",
        "tags": {
            "backup_policy": "daily",
            "owner": "data-team"
        },
        "properties": {"location": "US"}
    }
}

# 2. FAIL: Missing backup label
test_fail_missing_label {
    result == "fail" with input as {
        "name": "unprotected-data",
        "type": "google_bigquery_dataset",
        "tags": {
            "owner": "data-team"
        },
        "properties": {"location": "US"}
    }
}

# 3. FAIL: Invalid backup schedule
test_fail_invalid_schedule {
    result == "fail" with input as {
        "name": "rogue-data",
        "type": "google_bigquery_dataset",
        "tags": {
            "backup_policy": "never"
        },
        "properties": {"location": "US"}
    }
}
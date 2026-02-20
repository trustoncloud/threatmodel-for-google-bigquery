package wiz

# --- TEST 1: PASS - Valid Safe Transfer ---
test_pass_valid {
    result == "pass" with input as {
        "type": "google_bigquery_datatransfer_config",
        "name": "safe-load",
        "properties": {
            "dataSourceId": "google_cloud_storage",
            "destinationDatasetId": "raw_ingestion_zone",
            "serviceAccountName": "etl-loader@my-project.iam.gserviceaccount.com",
            "params": {
                "data_path_template": "gs://trusted-corp-data/file.csv",
                "delete_source_files": "false"
            }
        }
    }
}

# --- TEST 2: FAIL - Destructive Action (Delete Files) ---
test_fail_destructive {
    result == "fail" with input as {
        "type": "google_bigquery_datatransfer_config",
        "name": "dangerous-load",
        "properties": {
            "dataSourceId": "google_cloud_storage",
            "destinationDatasetId": "raw_ingestion_zone",
            "serviceAccountName": "etl-loader@my-project.iam.gserviceaccount.com",
            "params": {
                "data_path_template": "gs://trusted-corp-data/file.csv",
                "delete_source_files": "true" # DANGER
            }
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Identity (Privilege Escalation) ---
test_fail_identity {
    result == "fail" with input as {
        "type": "google_bigquery_datatransfer_config",
        "name": "admin-escalation",
        "properties": {
            "dataSourceId": "google_cloud_storage",
            "destinationDatasetId": "raw_ingestion_zone",
            # This SA is NOT in the allowlist
            "serviceAccountName": "super-admin@my-project.iam.gserviceaccount.com",
            "params": {
                "data_path_template": "gs://trusted-corp-data/file.csv"
            }
        }
    }
}

# --- TEST 4: FAIL - Bad Path (Data Exfiltration/Ingestion) ---
test_fail_path {
    result == "fail" with input as {
        "type": "google_bigquery_datatransfer_config",
        "name": "bad-path",
        "properties": {
            "dataSourceId": "google_cloud_storage",
            "destinationDatasetId": "raw_ingestion_zone",
            "serviceAccountName": "etl-loader@my-project.iam.gserviceaccount.com",
            "params": {
                "data_path_template": "gs://hacker-bucket/malware.csv"
            }
        }
    }
}
package wiz

# --- TEST 1: EXTERNAL TABLE ---

# PASS: Table pointing to trusted bucket
test_pass_table {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "sales-data",
        "properties": {
            "externalDataConfiguration": {
                "sourceUris": ["gs://my-corp-data-lake/2023/sales.csv"]
            }
        }
    }
}

# FAIL: Table pointing to hacker bucket
test_fail_table {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "malicious-link",
        "properties": {
            "externalDataConfiguration": {
                "sourceUris": ["gs://hacker-bucket/malware.csv"]
            }
        }
    }
}

# --- TEST 2: JOBS ---

# PASS: Load Job from trusted source
test_pass_job_load {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "nightly-load",
        "properties": {
            "configuration": {
                "load": {
                    "sourceUris": ["gs://partner-upload-bucket/incoming/*.json"]
                }
            }
        }
    }
}

# FAIL: Extract Job (Exfiltration) to untrusted destination
test_fail_job_extract {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "data-leak",
        "properties": {
            "configuration": {
                "extract": {
                    "destinationUris": ["gs://public-drop-zone/leak.csv"]
                }
            }
        }
    }
}

# --- TEST 3: NATIVE TABLE ---
# SKIP: Native tables don't have external URIs
test_skip_native {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "properties": {
            # No externalDataConfiguration
        }
    }
}
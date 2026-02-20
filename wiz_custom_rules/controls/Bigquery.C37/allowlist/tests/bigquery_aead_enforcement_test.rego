package wiz

# --- TEST 1: PASS - Encrypted Insert ---
test_pass_encrypted_insert {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "secure-insert",
        "properties": {
            "configuration": {
                "query": {
                    "query": "INSERT INTO employees VALUES (AEAD.ENCRYPT(keyset, 'secret_data'))"
                }
            },
            "statistics": {
                "query": {
                    "referencedTables": [
                        {"projectId": "my-project", "datasetId": "hr_data", "tableId": "employees"}
                    ]
                }
            }
        }
    }
}

# --- TEST 2: FAIL - Plaintext Insert ---
test_fail_plaintext_insert {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "leak-insert",
        "properties": {
            "configuration": {
                "query": {
                    "query": "INSERT INTO employees VALUES ('clear_text_secret')"
                }
            },
            "statistics": {
                "query": {
                    "referencedTables": [
                        # This matches the sensitive table list
                        {"projectId": "my-project", "datasetId": "hr_data", "tableId": "employees"}
                    ]
                }
            }
        }
    }
}

# --- TEST 3: SKIP - Irrelevant Table ---
test_skip_public_data {
    result == "skip" with input as {
        "type": "google_bigquery_job",
        "name": "public-query",
        "properties": {
            "configuration": {
                "query": { "query": "SELECT * FROM public_data" }
            },
            "statistics": {
                "query": {
                    "referencedTables": [
                        {"projectId": "other", "datasetId": "public", "tableId": "weather"}
                    ]
                }
            }
        }
    }
}
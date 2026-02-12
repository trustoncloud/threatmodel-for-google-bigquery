package wiz

# --- TEST 1: PASS - Compliant Retention ---
test_pass_compliant {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/clean_data",
        "properties": {
            # Created at T=0
            "creationTime": "1000000000000",
            # Expires at T + 30 days (approx)
            "expirationTime": "1002592000000" 
        }
    }
}

# --- TEST 2: FAIL - No Expiration (Infinite) ---
test_fail_no_expiration {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/zombie_data",
        "properties": {
            "creationTime": "1000000000000"
            # expirationTime missing or "0"
        }
    }
}

# --- TEST 3: FAIL - Excessive Retention ---
test_fail_excessive_retention {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/hoarded_data",
        "properties": {
            "creationTime": "1000000000000",
            # Expires at T + 400 days (Limit is 365)
            # 400 days * 24 * 60 * 60 * 1000 = 34560000000 ms
            "expirationTime": "1034560000000" 
        }
    }
}

# --- TEST 4: SKIP - Not a Table ---
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset", # Should be ignored
        "name": "projects/p1/datasets/d1"
    }
}
package wiz

# --- TEST 1: PASS - Compliant Model ---
test_pass_compliant {
    result == "pass" with input as {
        "type": "google_bigquery_model",
        "name": "projects/p1/datasets/d1/models/churn_prediction_v1",
        "properties": {
            # Created T=0
            "creationTime": "1000000000000",
            # Expires T+30 days
            "expirationTime": "1002592000000"
        }
    }
}

# --- TEST 2: FAIL - No Expiration (Zombie Model) ---
test_fail_no_expiration {
    result == "fail" with input as {
        "type": "google_bigquery_model",
        "name": "projects/p1/datasets/d1/models/legacy_model",
        "properties": {
            "creationTime": "1000000000000"
            # expirationTime missing
        }
    }
}

# --- TEST 3: FAIL - Excessive Lifespan ---
test_fail_excessive_lifespan {
    result == "fail" with input as {
        "type": "google_bigquery_model",
        "name": "projects/p1/datasets/d1/models/long_term_model",
        "properties": {
            "creationTime": "1000000000000",
            # Expires T+400 days (Limit 365)
            # 400 * 86400000 = 34560000000
            "expirationTime": "1034560000000"
        }
    }
}

# --- TEST 4: SKIP - Wrong Resource ---
test_skip_table {
    result == "skip" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/t1"
    }
}
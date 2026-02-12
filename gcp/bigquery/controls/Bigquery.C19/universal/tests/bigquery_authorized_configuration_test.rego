package wiz

# --- TEST 1: PASS - Secure Baseline ---
test_pass_secure {
    result == "pass" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/p1/datasets/secure_ds",
        "properties": {
            # Expiration is set (Value doesn't matter for Universal, as long as it exists)
            "defaultTableExpirationMs": "86400000",
            # Time Travel is default (implied 168 or set explicitly)
            "maxTimeTravelHours": "168"
        }
    }
}

# --- TEST 2: FAIL - Infinite Retention (No Expiration) ---
test_fail_infinite_retention {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/p1/datasets/forever_ds",
        "properties": {
            # "defaultTableExpirationMs" is MISSING -> FAIL
            "maxTimeTravelHours": "48"
        }
    }
}

# --- TEST 3: FAIL - Excessive Time Travel (Compliance Risk) ---
test_fail_long_time_travel {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/p1/datasets/audit_risk_ds",
        "properties": {
            "defaultTableExpirationMs": "86400000",
            # 14 days -> Exceeds 7 day security limit
            "maxTimeTravelHours": "336"
        }
    }
}
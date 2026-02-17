package wiz

# --- TEST 1: PASS - Native Dataset (Not a Subscription) ---
test_pass_native {
    result == "pass" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/my-org/datasets/native_ds",
        "properties": {
            # Missing "linkedDatasetSource" means it's a normal dataset
        }
    }
}

# --- TEST 2: PASS - Authorized Public Subscription ---
test_pass_authorized_public {
    result == "pass" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/my-org/datasets/crypto_copy",
        "properties": {
            "linkedDatasetSource": {
                # Matches "^projects/bigquery-public-data/datasets/.*$"
                "sourceDataset": "projects/bigquery-public-data/datasets/crypto_bitcoin"
            }
        }
    }
}

# --- TEST 3: PASS - Authorized Internal Link ---
test_pass_internal_link {
    result == "pass" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/my-org/datasets/marketing_view",
        "properties": {
            "linkedDatasetSource": {
                # Matches "^projects/my-org-.*$"
                "sourceDataset": "projects/my-org-marketing/datasets/campaigns"
            }
        }
    }
}

# --- TEST 4: FAIL - Unauthorized External Subscription ---
test_fail_rogue_subscription {
    result == "fail" with input as {
        "type": "google_bigquery_dataset",
        "name": "projects/my-org/datasets/shadow_it_data",
        "properties": {
            "linkedDatasetSource": {
                # This source is NOT in the allowlist
                "sourceDataset": "projects/unknown-vendor-inc/datasets/leaked_data"
            }
        }
    }
}
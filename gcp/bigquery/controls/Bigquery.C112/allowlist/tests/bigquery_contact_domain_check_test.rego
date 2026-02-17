package wiz

# --- TEST 1: PASS - Authorized Exchange Contact ---
test_pass_exchange_valid {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "valid-exchange",
        "properties": {
            "primaryContact": "admin@yourcompany.com" # Matches allowed domain
        }
    }
}

# --- TEST 2: PASS - Authorized Listing Contact ---
test_pass_listing_valid {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "valid-listing",
        "properties": {
            "primaryContact": "sales@subsidiary.com" # Matches allowed domain
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Personal Email (Exchange) ---
test_fail_exchange_gmail {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_data_exchange",
        "name": "rogue-exchange",
        "properties": {
            "primaryContact": "developer123@gmail.com" # FAIL
        }
    }
}

# --- TEST 4: FAIL - Unauthorized Vendor Email (Listing) ---
test_fail_listing_vendor {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "rogue-listing",
        "properties": {
            "primaryContact": "consultant@external-vendor.com" # FAIL (Not in allowlist)
        }
    }
}

# --- TEST 5: PASS - No Contact (Skipped by this control) ---
# Note: Missing contacts are handled by Governance controls (C97/C100), not this validity check.
test_pass_no_contact {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "incomplete-listing",
        "properties": {
            # "primaryContact" is missing
        }
    }
}
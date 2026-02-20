package wiz

# --- TEST 1: PASS - Secure Private Listing (Restricted) ---
test_pass_secure {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "secure-listing",
        "properties": {
            "discoveryType": "PRIVATE",
            "description": "Sensitive Data",
            "documentation": "https://docs",
            "restrictedExportConfig": { "enabled": true } # Safe
        }
    }
}

# --- TEST 2: PASS - Allowed Exportable Listing (Exception) ---
test_pass_allowed_export {
    result == "pass" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        # Matches the allowlist in the Rego
        "name": "projects/p1/locations/us/dataExchanges/e1/listings/public_holidays",
        "properties": {
            "discoveryType": "PRIVATE",
            "description": "Reference Data",
            "documentation": "https://docs",
            "restrictedExportConfig": { "enabled": false } # Allowed via Exception
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Export (Leaky Listing) ---
test_fail_leaky {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "projects/p1/locations/us/dataExchanges/e1/listings/sensitive_leak",
        "properties": {
            "discoveryType": "PRIVATE",
            "description": "Oops",
            "documentation": "https://docs",
            "restrictedExportConfig": { "enabled": false } # FAIL: Not in allowlist
        }
    }
}

# --- TEST 4: FAIL - Unauthorized Public Listing ---
test_fail_public {
    result == "fail" with input as {
        "type": "google_bigquery_analytics_hub_listing",
        "name": "public-listing",
        "properties": {
            "discoveryType": "PUBLIC", # Only PRIVATE allowed
            "description": "desc",
            "documentation": "docs",
            "restrictedExportConfig": { "enabled": true }
        }
    }
}
package wiz

# --- TEST 1: PASS - Authorized & Enabled ---
test_pass_valid {
    result == "pass" with input as {
        "type": "google_project",
        "name": "projects/data-science-prod",
        "properties": {
            "enabledServices": [
                "bigquery.googleapis.com",
                "cloudaicompanion.googleapis.com" # Present & Authorized
            ]
        }
    }
}

# --- TEST 2: PASS - Unauthorized & Disabled (Secure) ---
test_pass_secure {
    result == "pass" with input as {
        "type": "google_project",
        "name": "projects/legacy-finance", # Not in allowlist
        "properties": {
            "enabledServices": [
                "bigquery.googleapis.com"
                # Gemini Missing = Correct
            ]
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Enablement (Shadow AI) ---
test_fail_shadow_ai {
    result == "fail" with input as {
        "type": "google_project",
        "name": "projects/intern-sandbox", # Not in allowlist
        "properties": {
            "enabledServices": [
                "cloudaicompanion.googleapis.com" # FAIL: Shouldn't be here
            ]
        }
    }
}

# --- TEST 4: FAIL - Missing Enablement (Drift) ---
test_fail_drift {
    result == "fail" with input as {
        "type": "google_project",
        "name": "projects/innovation-lab", # Authorized
        "properties": {
            "enabledServices": [
                "bigquery.googleapis.com"
                # Gemini Missing = FAIL
            ]
        }
    }
}
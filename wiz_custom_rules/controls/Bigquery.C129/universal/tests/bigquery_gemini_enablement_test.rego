package wiz

# --- TEST 1: PASS - Clean Project (Standard Compliance) ---
# The most common scenario: Standard services are on, Gemini is off.
test_pass_clean {
    result == "pass" with input as {
        "type": "google_project",
        "name": "projects/prod-finance",
        "properties": {
            "enabledServices": [
                "bigquery.googleapis.com",
                "storage.googleapis.com",
                "compute.googleapis.com"
            ]
        }
    }
}

# --- TEST 2: FAIL - Explicit Violation (Shadow AI) ---
# The target scenario: Someone turned on Gemini.
test_fail_enabled {
    result == "fail" with input as {
        "type": "google_project",
        "name": "projects/shadow-ai-test",
        "properties": {
            "enabledServices": [
                "cloudaicompanion.googleapis.com"
            ]
        }
    }
}

# --- TEST 3: FAIL - Buried Violation (Needle in Haystack) ---
# Ensures the rule finds Gemini even if it's mixed with many other services.
test_fail_mixed_services {
    result == "fail" with input as {
        "type": "google_project",
        "name": "projects/mixed-workload",
        "properties": {
            "enabledServices": [
                "bigquery.googleapis.com",
                "storage.googleapis.com",
                "cloudaicompanion.googleapis.com", # <--- Hidden here
                "logging.googleapis.com"
            ]
        }
    }
}

# --- TEST 4: PASS - Empty Service List (Edge Case) ---
# Ensures the rule doesn't crash if the list is empty (Fails Safe).
test_pass_empty_services {
    result == "pass" with input as {
        "type": "google_project",
        "name": "projects/empty-proj",
        "properties": {
            "enabledServices": []
        }
    }
}

# --- TEST 5: PASS - Missing Property (Edge Case) ---
# Ensures the rule handles missing 'enabledServices' gracefully.
test_pass_missing_property {
    result == "pass" with input as {
        "type": "google_project",
        "name": "projects/legacy-proj",
        "properties": {
            # "enabledServices" is completely missing
            "otherField": "value"
        }
    }
}

# --- TEST 6: SKIP - Wrong Resource Type ---
# Ensures we don't accidentally flag Datasets or Tables.
test_skip_dataset {
    result == "skip" with input as {
        "type": "google_bigquery_dataset", # Not a project
        "name": "projects/p1/datasets/d1",
        "properties": {
            "enabledServices": ["cloudaicompanion.googleapis.com"] # Should be ignored on a dataset object
        }
    }
}
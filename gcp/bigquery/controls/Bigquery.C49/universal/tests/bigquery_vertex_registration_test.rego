package wiz

# --- TEST 1: PASS - Registered Model ---
test_pass_registered {
    result == "pass" with input as {
        "type": "google_bigquery_model",
        "name": "forecast_v1",
        "properties": {
            # Presence of this ID proves registration
            "vertexAiModelId": "projects/my-proj/locations/us/models/123456789"
        }
    }
}

# --- TEST 2: FAIL - Unregistered Model (Shadow AI) ---
test_fail_unregistered {
    result == "fail" with input as {
        "type": "google_bigquery_model",
        "name": "shadow_model",
        "properties": {
            # vertexAiModelId is missing
            "trainingRuns": [
                { "trainingOptions": { "modelType": "LINEAR_REG" } }
            ]
        }
    }
}

# --- TEST 3: SKIP - Other Resource ---
test_skip_table {
    result == "skip" with input as {
        "type": "google_bigquery_table"
    }
}
package wiz

# --- Logic ---
default result := "pass"

is_model { input.type == "google_bigquery_model" }

# 1. Check for Vertex AI Registration
# When a BQ Model is registered, the API populates the 'vertexAiModelId' field.
is_registered {
    # Check if the field exists and is not empty
    input.properties.vertexAiModelId
    input.properties.vertexAiModelId != ""
}

# 2. Failure Condition
# Fail if the model exists but has no link to Vertex AI
fail_not_registered {
    is_model
    not is_registered
}

result := "skip" {
    not is_model
} else := "fail" {
    fail_not_registered
}

# --- Metadata ---
currentConfiguration := "BigQuery ML Model is NOT registered with Vertex AI" {
    fail_not_registered
} else := sprintf("Model is registered in Vertex AI (ID: %v)", [input.properties.vertexAiModelId])

expectedConfiguration := "All BigQuery ML Models must be registered with the Vertex AI Model Registry."
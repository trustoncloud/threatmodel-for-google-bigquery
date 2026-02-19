package wiz

# --- Configuration ---
# Universal Policy:
# Gemini (Cloud AI Companion) must be DISABLED on all projects.
target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
default result := "pass"

is_project { input.type == "google_project" }

# Helper: Check if Gemini is enabled
is_gemini_enabled {
    services := object.get(input.properties, "enabledServices", [])
    services[_] == target_service
}

# Failure: Gemini is ON (Violation of Universal Ban)
fail_ai_enabled {
    is_project
    is_gemini_enabled
}

# --- Aggregation ---
result := "skip" {
    not is_project
} else := "fail" {
    fail_ai_enabled
}

# --- Metadata ---
currentConfiguration := "Gemini API is ENABLED" {
    fail_ai_enabled
} else := "Gemini API is DISABLED"

expectedConfiguration := "Gemini API must be disabled on all projects (Universal Ban)."
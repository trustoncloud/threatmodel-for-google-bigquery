package wiz

# --- Configuration ---
# Universal Policy:
# Gemini (Cloud AI Companion) must be DISABLED on all projects.
target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
default result := "pass"

# Enabled services arrive as the top-level serviceUsage array on the Wiz
# project payload (null when the aggregation is unavailable).
enabled_services := s {
    s := input.serviceUsage
    s != null
} else := []

# Helper: Check if Gemini is enabled
is_gemini_enabled {
    enabled_services[_] == target_service
}

# Failure: Gemini is ON (Violation of Universal Ban)
fail_ai_enabled {
    is_gemini_enabled
}

# --- Aggregation ---
result := "skip" {
    not input.projectId
} else := "fail" {
    fail_ai_enabled
}

# --- Metadata ---
currentConfiguration := "Gemini API is ENABLED" {
    fail_ai_enabled
} else := "Gemini API is DISABLED"

expectedConfiguration := "Gemini API must be disabled on all projects (Universal Ban)."

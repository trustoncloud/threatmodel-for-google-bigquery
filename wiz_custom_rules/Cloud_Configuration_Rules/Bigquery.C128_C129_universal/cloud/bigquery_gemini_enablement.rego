package wiz

# --- Configuration ---
# Universal Policy:
# Gemini (Cloud AI Companion) must be DISABLED on all projects.
target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
default result := "pass"

# Enabled services arrive as the top-level serviceUsage array on the project
# payload. A null or absent value means the list was not collected, which is
# no evidence that Gemini is off, so the project is skipped.
service_list_collected {
    is_array(input.serviceUsage)
}

# Helper: Check if Gemini is enabled
is_gemini_enabled {
    input.serviceUsage[_] == target_service
}

# Failure: Gemini is ON (Violation of Universal Ban)
fail_ai_enabled {
    is_gemini_enabled
}

# --- Aggregation ---
result := "skip" {
    not input.projectId
} else := "skip" {
    not service_list_collected
} else := "fail" {
    fail_ai_enabled
}

# --- Metadata ---
currentConfiguration := "The project's enabled services were not collected, so Gemini enablement is unknown" {
    not service_list_collected
} else := "Gemini API is ENABLED" {
    fail_ai_enabled
} else := "Gemini API is DISABLED"

expectedConfiguration := "Gemini API must be disabled on all projects (Universal Ban)."

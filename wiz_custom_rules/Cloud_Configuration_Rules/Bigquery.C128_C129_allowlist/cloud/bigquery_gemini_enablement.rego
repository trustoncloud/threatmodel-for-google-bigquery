package wiz

# --- Configuration ---
# List of project IDs authorized to use Gemini (AI Companion).
authorized_gemini_projects := {
    "data-science-prod",
    "innovation-lab"
}

# The API Service that controls Gemini in BigQuery
# "cloudaicompanion.googleapis.com" is the core service for Gemini for Google Cloud.
target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
default result := "pass"

# Enabled services arrive as the top-level serviceUsage array on the Wiz
# project payload (null when the aggregation is unavailable).
enabled_services := s {
    s := input.serviceUsage
    s != null
} else := []

# Helper: Check if Gemini API is enabled
is_gemini_enabled {
    enabled_services[_] == target_service
}

# Helper: Check if Project is Authorized (allowlist keyed by bare projectId)
is_project_authorized {
    authorized_gemini_projects[input.projectId]
}

# 1. Security Check: Unauthorized Enablement (Shadow AI)
# The API is ON, but the project is NOT in the allowlist.
fail_unauthorized_enablement {
    is_gemini_enabled
    not is_project_authorized
}

# 2. Drift Check: Missing Enablement (Availability)
# The project IS in the allowlist, but the API is OFF.
fail_missing_enablement {
    is_project_authorized
    not is_gemini_enabled
}

# --- Aggregation ---
result := "skip" {
    not input.projectId
} else := "fail" {
    fail_unauthorized_enablement
} else := "fail" {
    fail_missing_enablement
}

# --- Metadata ---
currentConfiguration := "Gemini API is ENABLED" {
    is_gemini_enabled
} else := "Gemini API is DISABLED"

expectedConfiguration := "Gemini API must be enabled ONLY for authorized projects."

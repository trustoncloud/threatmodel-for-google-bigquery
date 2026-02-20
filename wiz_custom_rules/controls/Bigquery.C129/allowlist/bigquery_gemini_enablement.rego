package wiz

# --- Configuration ---
# List of Project IDs authorized to use Gemini (AI Companion).
authorized_gemini_projects := {
    "projects/data-science-prod",
    "projects/innovation-lab"
}

# The API Service that controls Gemini in BigQuery
# "cloudaicompanion.googleapis.com" is the core service for Gemini for Google Cloud.
target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
default result := "pass"

is_project { input.type == "google_project" }

# Helper: Check if Gemini API is enabled
# Assumes 'enabledServices' is a list of service strings on the project resource.
is_gemini_enabled {
    services := object.get(input.properties, "enabledServices", [])
    services[_] == target_service
}

# Helper: Check if Project is Authorized
is_project_authorized {
    authorized_gemini_projects[input.name]
}

# 1. Security Check: Unauthorized Enablement (Shadow AI)
# The API is ON, but the project is NOT in the allowlist.
fail_unauthorized_enablement {
    is_project
    is_gemini_enabled
    not is_project_authorized
}

# 2. Drift Check: Missing Enablement (Availability)
# The project IS in the allowlist, but the API is OFF.
fail_missing_enablement {
    is_project
    is_project_authorized
    not is_gemini_enabled
}

# --- Aggregation ---
result := "skip" {
    not is_project
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
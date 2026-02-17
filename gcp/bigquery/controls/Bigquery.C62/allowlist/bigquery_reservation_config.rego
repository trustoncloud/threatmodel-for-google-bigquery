package wiz

# --- Configuration ---
# 1. Authorized configuration for RESERVATIONS
authorized_reservation_config := {
    "editions": {"ENTERPRISE", "ENTERPRISE_PLUS"},
    "ignoreIdleSlots": true,    # Must be strictly true, or strictly false
    "max_slots_limit": 2000     # The reservation cannot exceed this size
}

# 2. Authorized configuration for ASSIGNMENTS
authorized_assignment_config := {
    "job_types": {"QUERY", "PIPELINE", "ML_EXTERNAL"},
    # List of allowed projects/folders/orgs that can be assignees
    "allowed_assignees": {
        "projects/my-data-project",
        "folders/123456789"
    }
}

# --- Logic ---
default result := "pass"

# Identify Resource Types
is_reservation { input.type == "google_bigquery_reservation" }
is_assignment  { input.type == "google_bigquery_reservation_assignment" }

# --- RESERVATION CHECKS ---
fail_reservation_edition {
    is_reservation
    actual_edition := input.properties.edition
    not authorized_reservation_config.editions[actual_edition]
}

fail_reservation_idle {
    is_reservation
    # Default to false if missing
    actual_idle := object.get(input.properties, "ignoreIdleSlots", false)
    actual_idle != authorized_reservation_config.ignoreIdleSlots
}

fail_reservation_capacity {
    is_reservation
    actual_slots := to_number(input.properties.slotCapacity)
    actual_slots > authorized_reservation_config.max_slots_limit
}

# --- ASSIGNMENT CHECKS ---
fail_assignment_job_type {
    is_assignment
    actual_type := input.properties.jobType
    not authorized_assignment_config.job_types[actual_type]
}

fail_assignment_assignee {
    is_assignment
    actual_assignee := input.properties.assignee
    not authorized_assignment_config.allowed_assignees[actual_assignee]
}

# --- Aggregated Result ---
result := "skip" {
    not is_reservation
    not is_assignment
} else := "fail" {
    fail_reservation_edition
} else := "fail" {
    fail_reservation_idle
} else := "fail" {
    fail_reservation_capacity
} else := "fail" {
    fail_assignment_job_type
} else := "fail" {
    fail_assignment_assignee
}

# --- Metadata ---
currentConfiguration := "Reservation configuration is unauthorized (Edition/Idle/Capacity)" {
    is_reservation
    result == "fail"
} else := "Assignment configuration is unauthorized (JobType/Assignee)" {
    is_assignment
    result == "fail"
} else := "Configuration is authorized"

expectedConfiguration := "BigQuery Reservations and Assignments must match the authorized configuration allowlist."
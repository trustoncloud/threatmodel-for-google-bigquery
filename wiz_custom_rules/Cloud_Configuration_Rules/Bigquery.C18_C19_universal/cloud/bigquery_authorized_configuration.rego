package wiz

# --- Configuration ---
# Universal Security Baseline
# 1. Require Default Expiration? (True/False)
# Security Goal: Data Minimization. Prevents infinite retention of data.
require_table_expiration := true

# 2. Max Time Travel Allowed (Hours)
# Security Goal: Secure Deletion. Ensures deleted data is purged within a fixed window.
# BigQuery default is 168 hours (7 days). Set to -1 to disable.
max_time_travel_hours := 168

# --- Logic ---
default result := "pass"

# Helper: Get Expiration (unset arrives as "0")
get_expiration = val {
    val := to_number(object.get(input, "defaultTableExpirationMs", "0"))
}

# Helper: Get Time Travel ("0" = unset, GCP applies the 168h default)
get_time_travel = val {
    raw := object.get(input, "maxTimeTravelHours", "0")
    raw != "0"
    val := to_number(raw)
} else = 168 {
    true
}

# Failure 1: Missing Expiration (Security Risk: Infinite Retention)
fail_missing_expiration {
    require_table_expiration

    # Fail if expiration is effectively zero (missing or explicitly 0)
    exp := get_expiration
    exp == 0
}

# Failure 2: Excessive Time Travel (Security Risk: Delayed Deletion)
fail_excessive_time_travel {
    max_time_travel_hours != -1

    current_tt := get_time_travel
    current_tt > max_time_travel_hours
}

# --- Aggregation ---
result := "skip" {
    not input.datasetReference
} else := "fail" {
    fail_missing_expiration
} else := "fail" {
    fail_excessive_time_travel
}

# --- Metadata ---
currentConfiguration := sprintf("Expiration=%v ms, TimeTravel=%v hrs", [get_expiration, get_time_travel]) {
    result == "fail"
} else := "Dataset configuration meets security baselines"

expectedConfiguration := "Datasets must have a default expiration set and Time Travel must be within the 7-day limit."

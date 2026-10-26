package wiz

# --- Configuration ---
# Standard requirement: Minimum 48 hours (2 days) to maximum 168 hours (7 days)
# Adjust 'min_required_hours' based on your policy.
min_required_hours := 48

# --- Logic ---
default result := "pass"

# Retrieve time travel window ("0" = unset, GCP applies the 168h default)
actual_hours := val {
    raw := object.get(input, "maxTimeTravelHours", "0")
    raw != "0"
    val := to_number(raw)
} else := 168 {
    true
}

result := "skip" {
    not input.datasetReference
} else := "fail" {
    actual_hours < min_required_hours
}

# --- Metadata ---
currentConfiguration := sprintf("Time travel window is %v hours", [actual_hours])
expectedConfiguration := sprintf("BigQuery dataset time travel must be at least %v hours", [min_required_hours])

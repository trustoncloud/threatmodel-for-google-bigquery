package wiz

# --- Configuration ---
# Standard requirement: Minimum 48 hours (2 days) to maximum 168 hours (7 days)
# Adjust 'min_required_hours' based on your policy.
min_required_hours := 48

# --- Logic ---
default result := "pass"

# Retrieve time travel window
# If not set, GCP defaults to 168 hours (Pass), but we should check the explicit value if present.
time_travel_val := object.get(input.properties, "maxTimeTravelHours", "168")
actual_hours := to_number(time_travel_val)

result := "skip" {
    not input.properties
} else := "fail" {
    actual_hours < min_required_hours
}

# --- Metadata ---
currentConfiguration := sprintf("Time travel window is %v hours", [actual_hours])
expectedConfiguration := sprintf("BigQuery dataset time travel must be at least %v hours", [min_required_hours])
package wiz

# --- Configuration ---
# Requirement: Staleness must be between 30 minutes and 7 days.

# 30 Minutes = 30 * 60 = 1800 seconds
min_staleness_seconds := 1800

# 7 Days = 7 * 24 * 60 * 60 = 604,800 seconds
max_staleness_seconds := 604800

allowed_modes := {
    "AUTOMATIC",
    "MANUAL"
}

# --- Logic ---
default result := "pass"

is_table { input.type == "google_bigquery_table" }

# Check if it is an External Table (BigLake)
is_external_table {
    is_table
    input.properties.externalDataConfiguration
}

# 1. Get Cache Mode (Default to "DISABLED" if not set)
cache_mode := object.get(input.properties.externalDataConfiguration, "metadataCacheMode", "DISABLED")

# 2. Get Staleness
# maxStaleness is a string like "3600s"
current_staleness_raw := object.get(input.properties, "maxStaleness", "0s")

# Convert "3600s" -> 3600 integer
current_staleness_seconds := seconds {
    ns := time.parse_duration_ns(current_staleness_raw)
    seconds := ns / 1000000000
}

# --- Failure Conditions ---

# FAIL: Mode is invalid (must be AUTOMATIC or MANUAL)
fail_invalid_mode {
    is_external_table
    # Only check active configurations
    cache_mode != "DISABLED"
    not allowed_modes[cache_mode]
}

# FAIL: Staleness is TOO SHORT (Cost/Performance Risk)
fail_staleness_too_short {
    is_external_table
    cache_mode != "DISABLED"
    current_staleness_seconds < min_staleness_seconds
}

# FAIL: Staleness is TOO LONG (Data Freshness Risk)
fail_staleness_too_long {
    is_external_table
    cache_mode != "DISABLED"
    current_staleness_seconds > max_staleness_seconds
}

result := "skip" {
    not is_external_table
} else := "fail" {
    fail_invalid_mode
} else := "fail" {
    fail_staleness_too_short
} else := "fail" {
    fail_staleness_too_long
}

# --- Metadata ---
currentConfiguration := sprintf("Staleness: %vs (Limit: %v-%vs)", [current_staleness_seconds, min_staleness_seconds, max_staleness_seconds]) {
    fail_staleness_too_short
} else := sprintf("Staleness: %vs (Limit: %v-%vs)", [current_staleness_seconds, min_staleness_seconds, max_staleness_seconds]) {
    fail_staleness_too_long
} else := sprintf("Configuration OK: %v / %vs", [cache_mode, current_staleness_seconds])

expectedConfiguration := sprintf("External Table staleness must be between %v and %v seconds.", [min_staleness_seconds, max_staleness_seconds])
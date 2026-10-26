package wiz

# --- Configuration ---
# Keep in sync with the terraform matcher. Expirations are milliseconds:
# 60 days (5184000000) or 30 days (2592000000).
authorized_locations := {"US", "us-central1"}
authorized_table_expirations_ms := {5184000000, 2592000000}
authorized_partition_expirations_ms := {5184000000}

# --- Logic ---
default result := "pass"

# 1. Check Location (names are case-insensitive: "us" and "US" are the same multi-region)
location_authorized(loc) {
    lower(authorized_locations[_]) == lower(loc)
}

fail_location {
    not location_authorized(input.location)
}

# 2. Check Table Expiration (unset arrives as "0"; the universal leg handles absence)
fail_expiration {
    actual := object.get(input, "defaultTableExpirationMs", "0")
    actual != "0"
    not authorized_table_expirations_ms[to_number(actual)]
}

# 3. Check Partition Expiration (unset arrives as "0")
fail_partition {
    actual := object.get(input, "defaultPartitionExpirationMs", "0")
    actual != "0"
    not authorized_partition_expirations_ms[to_number(actual)]
}

result := "skip" {
    not input.datasetReference
} else := "fail" {
    fail_location
} else := "fail" {
    fail_expiration
} else := "fail" {
    fail_partition
}

# --- Metadata ---
currentConfiguration := "Location is unauthorized" {
    fail_location
} else := "Table Expiration is unauthorized" {
    fail_expiration
} else := "Partition Expiration is unauthorized" {
    fail_partition
} else := "Configuration is authorized"

expectedConfiguration := "BigQuery dataset configuration (Location, Expiration) must match the authorized allowlist."

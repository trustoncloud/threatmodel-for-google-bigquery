package wiz

# --- Configuration ---
authorized_config := {
    "location": {"US", "us-central1"},
    
    # 60 days (5184000000 ms) or 30 days (2592000000 ms)
    "defaultTableExpirationMs": {"5184000000", "2592000000"},
    
    # Added this missing key to fix the error
    "defaultPartitionExpirationMs": {"5184000000"} 
}

# --- Logic ---
default result := "pass"

# 1. Check Location
fail_location {
    actual := input.properties.location
    allowed := authorized_config.location
    not allowed[actual]
}

# 2. Check Table Expiration (Only if the resource has it set)
fail_expiration {
    actual := input.properties.defaultTableExpirationMs
    allowed := authorized_config.defaultTableExpirationMs
    not allowed[actual]
}

# 3. Check Partition Expiration (Only if the resource has it set)
fail_partition {
    actual := input.properties.defaultPartitionExpirationMs
    allowed := authorized_config.defaultPartitionExpirationMs
    not allowed[actual]
}

result := "skip" {
    not input.properties
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
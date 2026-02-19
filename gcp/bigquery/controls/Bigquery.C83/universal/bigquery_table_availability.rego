package wiz

# --- Configuration ---
# Universal Safety Baseline
# 1. Require Partition Filters? (True/False)
# If true, ALL partitioned tables must force users to include a WHERE clause.
# Security Goal: Availability (Anti-DoS) and Cost Control.
enforce_partition_filter := true

# --- Logic ---
default result := "pass"

is_table { input.type == "google_bigquery_table" }

# Helper: Check if table is partitioned (Time or Range)
is_partitioned {
    object.get(input.properties, "timePartitioning", null) != null
} else {
    object.get(input.properties, "rangePartitioning", null) != null
}

# Helper: Check if the safety filter is enabled
has_partition_filter {
    # Defaults to false if missing
    object.get(input.properties, "requirePartitionFilter", false) == true
}

# Failure: Table is partitioned but lacks the safety filter
fail_missing_partition_filter {
    is_table
    enforce_partition_filter
    
    # Logic: If it IS partitioned, it MUST have the filter.
    is_partitioned
    not has_partition_filter
}

# --- Aggregation ---
result := "skip" {
    not is_table
} else := "fail" {
    fail_missing_partition_filter
}

# --- Metadata ---
currentConfiguration := "Table is partitioned but allows full-scans (Missing requirePartitionFilter)" {
    fail_missing_partition_filter
} else := "Table safety configuration is authorized"

expectedConfiguration := "All partitioned BigQuery tables must have 'requirePartitionFilter' enabled to prevent resource exhaustion."
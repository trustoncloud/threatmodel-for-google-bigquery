package wiz

# --- Configuration ---
# Universal Security Baseline
enforce_restricted_export := true
enforce_restrict_query_result := true

# --- Logic ---
# Default to pass
default result := "pass"

is_listing { input.type == "google_bigquery_analytics_hub_listing" }

# Helper: Get Config Block (returns empty object if missing)
get_config := object.get(input.properties, "restrictedExportConfig", {})

# Failure 1: Restricted Export is Disabled
fail_export_disabled {
    is_listing
    enforce_restricted_export
    
    # Check if "enabled" is explicitly true. If missing or false -> Fail.
    object.get(get_config, "enabled", false) == false
}

# Failure 2: Query Result Export is Allowed (Leak Path)
fail_query_result_leak {
    is_listing
    enforce_restrict_query_result
    
    # Only relevant if the main feature is actually enabled (otherwise fail_export_disabled catches it)
    # We check that enabled is true here to avoid double reporting
    object.get(get_config, "enabled", false) == true
    
    # Check if "restrictQueryResult" is explicitly true.
    object.get(get_config, "restrictQueryResult", false) == false
}

# --- Aggregation ---
# Priority 1: Skip if not the right resource
result = "skip" {
    not is_listing
}

# Priority 2: Fail if any failure condition is met
else = "fail" {
    fail_export_disabled
}

else = "fail" {
    fail_query_result_leak
}

# (Default "pass" applies if none of the above match)

# --- Metadata ---
currentConfiguration = "Restricted Export is DISABLED" {
    fail_export_disabled
} else = "Query Result Export is ALLOWED (Restricted Export is partial)" {
    fail_query_result_leak
} else = "Restricted Export is fully enabled"

expectedConfiguration := "Analytics Hub Listings must have Restricted Export enabled with query result restrictions."
package wiz

# --- Configuration ---
# 1. Authorized Discovery Types
# Default to PRIVATE.
allowed_discovery_types := {"PRIVATE"}

# 2. Restricted Export Logic (The Key Differentiator)
# We default to requiring restricted export (View Only) for security.
# But we allow a specific list of "Exportable" listing IDs.
require_restricted_export_default := true

# List of Listing IDs allowed to have data export enabled (e.g., Reference Data)
allowed_exportable_listings := {
    "projects/p1/locations/us/dataExchanges/e1/listings/public_holidays",
    "projects/p1/locations/us/dataExchanges/e1/listings/zip_codes"
}

# 3. Governance
require_description := true
require_documentation := true

# --- Logic ---
default result := "pass"

is_listing { input.type == "google_bigquery_analytics_hub_listing" }

# Helper: Get fields
discovery_type := object.get(input.properties, "discoveryType", "DISCOVERY_TYPE_UNSPECIFIED")
description := object.get(input.properties, "description", "")
documentation := object.get(input.properties, "documentation", "")

# Helper: Check Restricted Export status
# Returns true if the listing effectively restricts export
is_export_restricted {
    config := object.get(input.properties, "restrictedExportConfig", {})
    object.get(config, "enabled", false) == true
}

# 1. Security Check: Unauthorized Public Exposure
fail_unauthorized_discovery {
    is_listing
    not allowed_discovery_types[discovery_type]
}

# 2. Security Check: Unrestricted Data Export (Exfiltration Risk)
fail_unrestricted_export {
    is_listing
    require_restricted_export_default == true
    
    # Check if the listing is actually restricted
    not is_export_restricted
    
    # Check if this listing is explicitly allowed to be exportable (Exception)
    not allowed_exportable_listings[input.name]
}

# 3. Governance Check: Missing Documentation
fail_missing_governance {
    is_listing
    require_description
    description == ""
}

fail_missing_documentation {
    is_listing
    require_documentation
    documentation == ""
}

# --- Aggregation ---
result := "skip" {
    not is_listing
} else := "fail" {
    fail_unauthorized_discovery
} else := "fail" {
    fail_unrestricted_export
} else := "fail" {
    fail_missing_governance
} else := "fail" {
    fail_missing_documentation
}

# --- Metadata ---
currentConfiguration := sprintf("Listing Config: Type='%v', RestrictedExport='%v'", [discovery_type, is_export_restricted]) {
    result == "fail"
} else := "Listing configuration is authorized"

expectedConfiguration := "Listings must be PRIVATE and have Restricted Export enabled (unless allowlisted)."
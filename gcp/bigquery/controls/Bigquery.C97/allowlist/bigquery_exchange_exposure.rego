package wiz

# --- Configuration ---
# 1. Authorized Discovery Types
# Default to PRIVATE only.
# "PUBLIC" allows visibility to all Analytics Hub users (potentially global).
allowed_discovery_types := {"PRIVATE"}

# 2. Public Exchange Allowlist (Exceptions)
# If you allow PUBLIC exchanges generally, you might rely on the rule above.
# If you block PUBLIC generally, list specific authorized IDs here.
authorized_public_exchanges := {
    "projects/my-org/locations/us/dataExchanges/official-public-dataset"
}

# --- Logic ---
default result := "pass"

is_exchange { input.type == "google_bigquery_analytics_hub_data_exchange" }

# Helper: Get discovery type (Defaults to UNSPECIFIED if missing)
discovery_type := object.get(input.properties, "discoveryType", "DISCOVERY_TYPE_UNSPECIFIED")

# 1. Security Check: Unauthorized Discovery Type
fail_unauthorized_discovery_type {
    is_exchange
    
    # Check if the current type is NOT in the allowed list
    not allowed_discovery_types[discovery_type]
    
    # AND check if this specific exchange is NOT an authorized exception
    not authorized_public_exchanges[input.name]
}

# --- Aggregation ---
result := "skip" {
    not is_exchange
} else := "fail" {
    fail_unauthorized_discovery_type
}

# --- Metadata ---
currentConfiguration := sprintf("Exchange Discovery Type is '%v'", [discovery_type]) {
    result == "fail"
} else := "Exchange Discovery Type is authorized"

expectedConfiguration := "Data Exchanges must use authorized Discovery Types (e.g., PRIVATE) or be explicitly allowlisted."
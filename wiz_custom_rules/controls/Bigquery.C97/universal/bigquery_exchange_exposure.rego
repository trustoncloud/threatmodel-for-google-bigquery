package wiz

# --- Logic ---
# Universal Mode: We strictly enforce "PRIVATE".

default result := "pass"

is_exchange { input.type == "google_bigquery_analytics_hub_data_exchange" }

# Helper: Get discovery type (Defaults to UNSPECIFIED if missing)
discovery_type := object.get(input.properties, "discoveryType", "DISCOVERY_TYPE_UNSPECIFIED")

# --- Failure Condition ---
# Fail if the type is NOT "PRIVATE"
fail_non_private_exchange {
    is_exchange
    discovery_type != "PRIVATE"
}

# --- Aggregation ---
result := "skip" {
    not is_exchange
} else := "fail" {
    fail_non_private_exchange
}

# --- Metadata ---
currentConfiguration := sprintf("Exchange Discovery Type is '%v'", [discovery_type]) {
    result == "fail"
} else := "Exchange is PRIVATE"

expectedConfiguration := "All Data Exchanges must be configured as PRIVATE."
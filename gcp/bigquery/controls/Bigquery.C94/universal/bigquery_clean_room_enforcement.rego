package wiz

# --- Logic ---
# Universal Mode: No configuration needed. 
# We simply fail if a Data Exchange lacks DCR config.

default result := "pass"

is_data_exchange { input.type == "google_bigquery_analytics_hub_data_exchange" }

# Check for Clean Room Configuration
# The presence of 'dcrExchangeConfig' confirms it is a DCR.
is_configured_as_dcr {
    input.properties.sharingEnvironmentConfig.dcrExchangeConfig
}

# --- Failure Condition ---
# Fail ANY exchange that is not a DCR
fail_not_clean_room {
    is_data_exchange
    not is_configured_as_dcr
}

# --- Aggregation ---
result := "skip" {
    not is_data_exchange
} else := "fail" {
    fail_not_clean_room
}

# --- Metadata ---
currentConfiguration := "Data Exchange is a Standard Exchange (Not a Clean Room)" {
    fail_not_clean_room
} else := "Data Exchange is a Data Clean Room"

expectedConfiguration := "All Data Exchanges must be configured as Data Clean Rooms (dcrExchangeConfig)."
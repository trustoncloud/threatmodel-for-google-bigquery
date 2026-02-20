package wiz

# --- Configuration ---
# List of Data Exchange IDs that are REQUIRED to be Data Clean Rooms.
required_clean_rooms := {
    "projects/prod-data-sharing/locations/us/dataExchanges/sensitive_partner_exchange",
    "projects/marketing-analytics/locations/us/dataExchanges/pii_clean_room"
}

# --- Logic ---
default result := "pass"

is_data_exchange { input.type == "google_bigquery_analytics_hub_data_exchange" }

# 1. Check if the Data Exchange is in our 'Required' list
is_required_dcr {
    is_data_exchange
    input.name == required_clean_rooms[_]
}

# 2. Check for Clean Room Configuration (Corrected Field)
# The presence of 'dcrExchangeConfig' in the union field confirms it is a DCR.
is_configured_as_dcr {
    input.properties.sharingEnvironmentConfig.dcrExchangeConfig
}

# --- Failure Conditions ---
fail_not_clean_room {
    is_required_dcr
    not is_configured_as_dcr
}

result := "skip" {
    not is_data_exchange
} else := "fail" {
    fail_not_clean_room
}

# --- Metadata ---
currentConfiguration := "Data Exchange is NOT configured as a Data Clean Room" {
    fail_not_clean_room
} else := "Data Exchange is correctly configured as a Data Clean Room" {
    is_configured_as_dcr
} else := "Standard Data Exchange (DCR not required)"

expectedConfiguration := "Designated sensitive Data Exchanges must be configured as Data Clean Rooms (dcrExchangeConfig)."
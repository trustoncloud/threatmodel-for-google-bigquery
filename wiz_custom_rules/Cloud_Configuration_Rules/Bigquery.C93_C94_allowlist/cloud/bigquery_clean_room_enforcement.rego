package wiz

# --- Configuration ---
# Data Exchanges that are REQUIRED to be Data Clean Rooms, by full resource
# name. NOTE: the name carries the project NUMBER, not the project id.
required_dcr_exchange_names := {
    "projects/111111111111/locations/us/dataExchanges/sensitive_partner_exchange",
    "projects/222222222222/locations/us/dataExchanges/pii_clean_room"
}

# --- Logic ---
default result := "pass"

# Exchange payloads use snake_case fields and carry the full path in name
is_exchange {
    contains(object.get(input, "name", ""), "/dataExchanges/")
}

# 1. Check if the Data Exchange is in our 'Required' list
is_required_dcr {
    required_dcr_exchange_names[input.name]
}

# 2. Check for Clean Room Configuration
# The DCR marker sits inside the Environment oneof wrapper.
is_configured_as_dcr {
    input.sharing_environment_config.Environment.DcrExchangeConfig
}

# --- Failure Conditions ---
fail_not_clean_room {
    is_required_dcr
    not is_configured_as_dcr
}

result := "skip" {
    not is_exchange
} else := "fail" {
    fail_not_clean_room
}

# --- Metadata ---
currentConfiguration := "Data Exchange is NOT configured as a Data Clean Room" {
    fail_not_clean_room
} else := "Data Exchange is correctly configured as a Data Clean Room" {
    is_configured_as_dcr
} else := "Standard Data Exchange (DCR not required)"

expectedConfiguration := "Designated sensitive Data Exchanges must be configured as Data Clean Rooms."

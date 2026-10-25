package wiz

# --- Logic ---
# Universal Mode: No configuration needed.
# Every Data Exchange must be configured as a Data Clean Room.

default result := "pass"

# Exchange payloads use snake_case fields and carry the full path in name
is_exchange {
    contains(object.get(input, "name", ""), "/dataExchanges/")
}

# Check for Clean Room Configuration
# The DCR marker sits inside the Environment oneof wrapper.
is_configured_as_dcr {
    input.sharing_environment_config.Environment.DcrExchangeConfig
}

result := "skip" {
    not is_exchange
} else := "fail" {
    not is_configured_as_dcr
}

# --- Metadata ---
currentConfiguration := "Data Exchange is NOT configured as a Data Clean Room" {
    result == "fail"
} else := "Data Exchange is configured as a Data Clean Room"

expectedConfiguration := "All Data Exchanges must be configured as Data Clean Rooms (DcrExchangeConfig)."

package wiz

# --- Logic ---
# Universal Mode: no Data Exchange may be published to the Analytics Hub
# marketplace (public discovery).

default result := "pass"

# Exchange payloads use snake_case fields and carry the full path in name
is_exchange {
    contains(object.get(input, "name", ""), "/dataExchanges/")
}

# discovery_type is an integer enum: 2 = published to the marketplace (public
# discovery), 1 = private, absent = not published (integer zero value).
discovery_type := object.get(input, "discovery_type", 0)

# --- Failure Condition ---
fail_published {
    discovery_type == 2
}

result := "skip" {
    not is_exchange
} else := "fail" {
    fail_published
}

# --- Metadata ---
currentConfiguration := "Exchange is published to the Analytics Hub marketplace" {
    fail_published
} else := "Exchange is not published to the marketplace"

expectedConfiguration := "No Data Exchange may be published to the Analytics Hub marketplace."

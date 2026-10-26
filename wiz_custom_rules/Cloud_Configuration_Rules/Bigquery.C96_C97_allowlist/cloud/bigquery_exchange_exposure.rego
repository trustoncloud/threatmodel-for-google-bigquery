package wiz

# --- Configuration ---
# Data Exchanges authorized to be published to the Analytics Hub marketplace
# (public discovery), by full resource name. All other exchanges must remain
# unpublished. NOTE: the name carries the project NUMBER, not the project id.
authorized_public_exchange_names := {
    "projects/111111111111/locations/us/dataExchanges/official_public_dataset"
}

# --- Logic ---
default result := "pass"

# Exchange payloads use snake_case fields and carry the full path in name
is_exchange {
    contains(object.get(input, "name", ""), "/dataExchanges/")
}

# discovery_type is an integer enum: 2 = published to the marketplace (public
# discovery), 1 = private, absent = not published (integer zero value).
discovery_type := object.get(input, "discovery_type", 0)

is_published {
    discovery_type == 2
}

# Failure: published to the marketplace without authorization
fail_unauthorized_publication {
    is_published
    not authorized_public_exchange_names[input.name]
}

# --- Aggregation ---
result := "skip" {
    not is_exchange
} else := "fail" {
    fail_unauthorized_publication
}

# --- Metadata ---
currentConfiguration := "Exchange is published to the Analytics Hub marketplace" {
    result == "fail"
} else := "Exchange is not published, or its publication is authorized"

expectedConfiguration := "Data Exchanges must not be published to the Analytics Hub marketplace unless explicitly allowlisted."

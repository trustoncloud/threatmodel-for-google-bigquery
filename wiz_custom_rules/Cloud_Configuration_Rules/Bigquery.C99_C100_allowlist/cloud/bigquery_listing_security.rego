package wiz

# --- Configuration ---
# 1. Listings allowed to have data export enabled (for example reference
#    data), by full resource name. The name carries the project NUMBER, not
#    the project ID.
authorized_exportable_listing_names := {
    "projects/111111111111/locations/us/dataExchanges/reference_data/listings/public_holidays"
}

# 2. Governance requirements. Keep in sync with the Terraform matcher.
require_description := true
require_documentation := true

# --- Logic ---
default result := "pass"

# A listing name ends in /dataExchanges/<exchange>/listings/<listing>.
is_listing {
    regex.match(`^projects/[^/]+/locations/[^/]+/dataExchanges/[^/]+/listings/[^/]+$`, object.get(input, "name", ""))
}

# discovery_type is an integer: 1 private, 2 publicly discoverable. A listing
# created without one reports the value of its exchange.
issues[msg] {
    input.discovery_type == 2
    msg := "the listing is publicly discoverable"
}

# Restricted export governs a shared dataset, so a listing that shares a
# Pub/Sub topic and no dataset is not held to it.
listing_shares_topic_only {
    is_object(input.Source.PubsubTopic)
    not input.Source.BigqueryDataset
}

listing_restricts_export {
    input.restricted_export_config.enabled == true
}

issues[msg] {
    not listing_shares_topic_only
    not listing_restricts_export
    not authorized_exportable_listing_names[input.name]
    msg := "the listing allows data export and is not an approved exportable listing"
}

# A text field left out arrives as an empty string.
is_blank(field) {
    trim_space(sprintf("%v", [object.get(input, field, "")])) == ""
}

issues[msg] {
    require_description
    is_blank("description")
    msg := "the listing has no description"
}

issues[msg] {
    require_documentation
    is_blank("documentation")
    msg := "the listing has no documentation"
}

# --- Aggregation ---
result := "skip" {
    not is_listing
} else := "fail" {
    count(issues) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Listing configuration is not approved: %v", [concat("; ", sort(issues))]) {
    result == "fail"
} else := "Listing is private, restricts export or is an approved exportable listing, and carries the required text"

expectedConfiguration := "A listing must be private (discovery_type 1), must restrict data export unless it is listed in authorized_exportable_listing_names, and must carry a description and documentation where those are required."

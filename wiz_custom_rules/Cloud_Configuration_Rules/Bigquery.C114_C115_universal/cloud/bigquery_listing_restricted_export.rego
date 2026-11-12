package wiz

# --- Logic ---
default result := "pass"

# A listing name ends in /dataExchanges/<exchange>/listings/<listing>.
is_listing {
    regex.match(`^projects/[^/]+/locations/[^/]+/dataExchanges/[^/]+/listings/[^/]+$`, object.get(input, "name", ""))
}

# Restricted export governs a shared dataset. A listing that shares a Pub/Sub
# topic and no dataset has nothing for it to restrict.
listing_shares_topic_only {
    is_object(input.Source.PubsubTopic)
    not input.Source.BigqueryDataset
}

# The three flags arrive as plain booleans, set to false when export is open.
listing_export_config := cfg {
    cfg := input.restricted_export_config
    is_object(cfg)
} else := {}

listing_export_enabled {
    listing_export_config.enabled == true
}

issues[msg] {
    not listing_export_enabled
    msg := "restricted export is disabled or not configured"
}

issues[msg] {
    listing_export_enabled
    object.get(listing_export_config, "restrict_query_result", false) != true
    msg := "query results derived from the listing can be exported"
}

# --- Aggregation ---
result := "skip" {
    not is_listing
} else := "skip" {
    listing_shares_topic_only
} else := "fail" {
    count(issues) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Listing: %v", [concat("; ", sort(issues))]) {
    result == "fail"
} else := "Listing shares a Pub/Sub topic, which restricted export does not govern" {
    is_listing
    listing_shares_topic_only
} else := "Restricted export is enabled and query results cannot be exported"

expectedConfiguration := "Every listing that shares a BigQuery dataset must enable restricted export (restricted_export_config.enabled) together with the query result restriction (restrict_query_result)."

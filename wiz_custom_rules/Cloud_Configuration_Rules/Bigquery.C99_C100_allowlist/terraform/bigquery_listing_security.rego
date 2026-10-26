package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# 1. Listings allowed to have data export enabled (e.g. reference data),
#    keyed by the listing_id declared on the resource.
authorized_exportable_listing_ids := {
    "public_holidays",
    "zip_codes"
}

# 2. Governance requirements
require_description := true

require_documentation := true

# --- Helpers ---
listing_export_restricted(l) {
    cfg := terraLib.getValueArrayOrObject(l.restricted_export_config)
    cfg.enabled == true
}

# --- Logic ---
# Finding: listing published to the marketplace (public discovery).
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    l.discovery_type == "DISCOVERY_TYPE_PUBLIC"

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].discovery_type", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "listings must not use public discovery",
        "keyActualValue": sprintf("listing '%v' is publicly discoverable", [l.listing_id]),
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: data export not restricted and listing not allowlisted.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    not listing_export_restricted(l)
    not authorized_exportable_listing_ids[l.listing_id]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].restricted_export_config.enabled", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "restricted_export_config.enabled must be true unless the listing is allowlisted as exportable",
        "keyActualValue": sprintf("listing '%v' allows data export", [l.listing_id]),
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: missing description (governance).
WizPolicy[result] {
    require_description
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    object.get(l, "description", "") == ""

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].description", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "listings must carry a description",
        "keyActualValue": "description is not set",
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: missing documentation (governance).
WizPolicy[result] {
    require_documentation
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    object.get(l, "documentation", "") == ""

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].documentation", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "listings must carry documentation",
        "keyActualValue": "documentation is not set",
        "resourceTags": object.get(l, "labels", {}),
    }
}

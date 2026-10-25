package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal baseline: every listing must enable restricted export, including
# the query-result restriction.

export_config(l) := cfg {
    cfg := terraLib.getValueArrayOrObject(l.restricted_export_config)
}

# Finding: restricted export disabled or missing.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    not export_enabled(l)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].restricted_export_config.enabled", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "restricted_export_config.enabled must be true",
        "keyActualValue": "restricted export is disabled or not configured",
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: restricted export enabled but query results still exportable.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    export_enabled(l)
    cfg := export_config(l)
    object.get(cfg, "restrict_query_result", false) != true

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].restricted_export_config.restrict_query_result", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "restricted_export_config.restrict_query_result must be true",
        "keyActualValue": "query results derived from the listing can be exported",
        "resourceTags": object.get(l, "labels", {}),
    }
}

export_enabled(l) {
    cfg := export_config(l)
    cfg.enabled == true
}

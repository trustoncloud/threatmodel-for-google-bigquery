package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal baseline: every listing that shares a BigQuery dataset must
# enable restricted export, including the query-result restriction.

export_config(l) := cfg {
    cfg := terraLib.getValueArrayOrObject(l.restricted_export_config)
}

# Restricted export governs a shared dataset. A listing that shares a Pub/Sub
# topic and no dataset has nothing for it to restrict. A listing with neither
# block written out (a source built by a dynamic block) is held to the rule.
shares_topic_only(l) {
    l.pubsub_topic
    not l.bigquery_dataset
}

# Finding: restricted export disabled or missing.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    not shares_topic_only(l)
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
    not shares_topic_only(l)
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

package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal Mode: no exchange may be published to the Analytics Hub
# marketplace (public discovery). Absent discovery_type = not published.
WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    ex.discovery_type == "DISCOVERY_TYPE_PUBLIC"

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].discovery_type", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "no exchange may be published to the Analytics Hub marketplace",
        "keyActualValue": sprintf("exchange '%v' is published (DISCOVERY_TYPE_PUBLIC)", [object.get(ex, "data_exchange_id", name)]),
        "resourceTags": object.get(ex, "labels", {}),
    }
}

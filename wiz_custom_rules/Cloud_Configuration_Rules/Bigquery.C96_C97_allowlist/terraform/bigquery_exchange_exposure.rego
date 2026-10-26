package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Exchanges authorized to be published to the Analytics Hub marketplace
# (public discovery), keyed by the data_exchange_id declared on the resource.
authorized_public_exchange_ids := {
    "official_public_dataset"
}

# --- Logic ---
# Finding: exchange published to the marketplace without authorization.
# Absent discovery_type means the exchange is not published.
WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    ex.discovery_type == "DISCOVERY_TYPE_PUBLIC"
    not authorized_public_exchange_ids[ex.data_exchange_id]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].discovery_type", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "exchanges must not be published to the marketplace unless allowlisted",
        "keyActualValue": sprintf("exchange '%v' is published (DISCOVERY_TYPE_PUBLIC)", [ex.data_exchange_id]),
        "resourceTags": object.get(ex, "labels", {}),
    }
}

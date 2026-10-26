package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Data exchanges your projects may subscribe to (creating linked datasets),
# keyed by the data_exchange_id declared on the subscription resource.
authorized_source_exchange_ids := {
    "governed_partner_exchange",
    "internal_reference_data"
}

# --- Logic ---
# Finding: subscription to an exchange outside the authorized set.
WizPolicy[result] {
    document := input.document[i]
    sub := document.resource.google_bigquery_analytics_hub_listing_subscription[name]
    not authorized_source_exchange_ids[sub.data_exchange_id]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing_subscription",
        "resourceName": terraLib.get_resource_name(sub, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing_subscription[%s].data_exchange_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("subscriptions may only target authorized exchanges: %v", [authorized_source_exchange_ids]),
        "keyActualValue": sprintf("subscription targets exchange '%v'", [sub.data_exchange_id]),
        "resourceTags": object.get(sub, "labels", {}),
    }
}

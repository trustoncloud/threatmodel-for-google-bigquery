package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Data Exchanges that are REQUIRED to be Data Clean Rooms, keyed by the
# data_exchange_id declared on the resource.
required_dcr_exchange_ids := {
    "sensitive_partner_exchange",
    "pii_clean_room"
}

# --- Helpers ---
exchange_is_dcr(ex) {
    cfg := terraLib.getValueArrayOrObject(ex.sharing_environment_config)
    cfg.dcr_exchange_config
}

# --- Logic ---
# Finding: required exchange declared without a Data Clean Room config.
WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    required_dcr_exchange_ids[ex.data_exchange_id]
    not exchange_is_dcr(ex)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].sharing_environment_config", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "designated sensitive exchanges must set sharing_environment_config.dcr_exchange_config",
        "keyActualValue": sprintf("exchange '%v' is not configured as a Data Clean Room", [ex.data_exchange_id]),
        "resourceTags": object.get(ex, "labels", {}),
    }
}

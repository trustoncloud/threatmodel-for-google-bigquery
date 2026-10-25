package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal Mode: every Data Exchange must be configured as a Data Clean Room.

exchange_is_dcr(ex) {
    cfg := terraLib.getValueArrayOrObject(ex.sharing_environment_config)
    cfg.dcr_exchange_config
}

WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    not exchange_is_dcr(ex)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].sharing_environment_config", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "every exchange must set sharing_environment_config.dcr_exchange_config",
        "keyActualValue": sprintf("exchange '%v' is not configured as a Data Clean Room", [object.get(ex, "data_exchange_id", name)]),
        "resourceTags": object.get(ex, "labels", {}),
    }
}

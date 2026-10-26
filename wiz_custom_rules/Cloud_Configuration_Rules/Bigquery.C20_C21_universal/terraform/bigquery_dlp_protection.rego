package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal baseline: a BigQuery DLP trigger must carry inspection rules,
# either a managed template reference or an inline inspect config.

inspect_job(trigger) := ij {
    ij := terraLib.getValueArrayOrObject(trigger.inspect_job)
}

targets_bigquery(trigger) {
    ij := inspect_job(trigger)
    sc := terraLib.getValueArrayOrObject(ij.storage_config)
    sc.big_query_options
}

has_inspection_rules(trigger) {
    ij := inspect_job(trigger)
    object.get(ij, "inspect_template_name", "") != ""
}

has_inspection_rules(trigger) {
    ij := inspect_job(trigger)
    ij.inspect_config
}

WizPolicy[result] {
    document := input.document[i]
    trigger := document.resource.google_data_loss_prevention_job_trigger[name]
    targets_bigquery(trigger)
    not has_inspection_rules(trigger)

    result := {
        "documentId": document.id,
        "resourceType": "google_data_loss_prevention_job_trigger",
        "resourceName": terraLib.get_resource_name(trigger, name),
        "searchKey": sprintf("google_data_loss_prevention_job_trigger[%s].inspect_job", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "BigQuery DLP triggers must set inspect_template_name or an inline inspect_config",
        "keyActualValue": "trigger scans BigQuery without inspection rules",
        "resourceTags": object.get(trigger, "labels", {}),
    }
}

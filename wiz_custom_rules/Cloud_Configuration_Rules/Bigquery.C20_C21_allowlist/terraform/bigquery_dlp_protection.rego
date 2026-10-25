package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Managed inspect templates authorized for BigQuery DLP scans. Inline
# inspect configurations are not authorized in allowlist mode.
authorized_templates := {
    "projects/my-project/inspectTemplates/strict-pii-v1",
    "projects/my-project/inspectTemplates/finance-pci-v1"
}

# --- Helpers ---
inspect_job(trigger) := ij {
    ij := terraLib.getValueArrayOrObject(trigger.inspect_job)
}

targets_bigquery(trigger) {
    ij := inspect_job(trigger)
    sc := terraLib.getValueArrayOrObject(ij.storage_config)
    sc.big_query_options
}

# --- Logic ---
# Finding: BigQuery DLP trigger without an authorized managed template.
WizPolicy[result] {
    document := input.document[i]
    trigger := document.resource.google_data_loss_prevention_job_trigger[name]
    targets_bigquery(trigger)
    ij := inspect_job(trigger)
    template := object.get(ij, "inspect_template_name", "")
    not authorized_templates[template]

    result := {
        "documentId": document.id,
        "resourceType": "google_data_loss_prevention_job_trigger",
        "resourceName": terraLib.get_resource_name(trigger, name),
        "searchKey": sprintf("google_data_loss_prevention_job_trigger[%s].inspect_job.inspect_template_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("BigQuery DLP triggers must use an authorized template: %v", [authorized_templates]),
        "keyActualValue": sprintf("inspect_template_name is '%v'", [template]),
        "resourceTags": object.get(trigger, "labels", {}),
    }
}

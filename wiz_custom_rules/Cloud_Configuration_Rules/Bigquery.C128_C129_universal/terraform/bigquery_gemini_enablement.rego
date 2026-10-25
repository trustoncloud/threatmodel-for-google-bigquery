package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Universal Policy: Gemini (Cloud AI Companion) must not be enabled.
target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
# Finding: Gemini API enablement declared.
WizPolicy[result] {
    document := input.document[i]
    svc := document.resource.google_project_service[name]
    svc.service == target_service

    result := {
        "documentId": document.id,
        "resourceType": "google_project_service",
        "resourceName": terraLib.get_resource_name(svc, name),
        "searchKey": sprintf("google_project_service[%s].service", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "cloudaicompanion.googleapis.com must not be enabled (universal ban)",
        "keyActualValue": "Gemini API enablement is declared",
        "resourceTags": object.get(svc, "labels", {}),
    }
}

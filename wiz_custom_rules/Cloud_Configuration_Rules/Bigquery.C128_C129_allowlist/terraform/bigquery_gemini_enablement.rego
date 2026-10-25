package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Projects authorized to enable Gemini (Cloud AI Companion), by project id.
authorized_gemini_projects := {
    "data-science-prod",
    "innovation-lab"
}

target_service := "cloudaicompanion.googleapis.com"

# --- Logic ---
# Finding: Gemini API enabled on a project outside the authorized set.
# An unset project attribute inherits the provider default and cannot be
# attributed, so it fails secure.
WizPolicy[result] {
    document := input.document[i]
    svc := document.resource.google_project_service[name]
    svc.service == target_service
    project := sprintf("%v", [object.get(svc, "project", "")])
    not project_authorized(project)

    result := {
        "documentId": document.id,
        "resourceType": "google_project_service",
        "resourceName": terraLib.get_resource_name(svc, name),
        "searchKey": sprintf("google_project_service[%s].service", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("Gemini may only be enabled on authorized projects: %v", [authorized_gemini_projects]),
        "keyActualValue": sprintf("cloudaicompanion.googleapis.com enabled on project '%v'", [project]),
        "resourceTags": object.get(svc, "labels", {}),
    }
}

project_authorized(project) {
    authorized_gemini_projects[project]
}

project_authorized(project) {
    allowed := authorized_gemini_projects[_]
    contains(project, allowed)
}

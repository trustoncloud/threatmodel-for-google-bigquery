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
# The project ID is compared exactly. A declaration with no project, or with
# a project the source does not state, cannot be tied to an approved project,
# so it is reported.
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
        "keyActualValue": sprintf("cloudaicompanion.googleapis.com enabled on %s", [project_description(project)]),
        "resourceTags": object.get(svc, "labels", {}),
    }
}

project_authorized(project) {
    not tocm_tf_unresolved(project)
    authorized_gemini_projects[project]
}

project_description(project) := "the provider default project, which the source does not state" {
    project == ""
} else := sprintf("project '%v', which is not known until apply", [project]) {
    tocm_tf_unresolved(project)
} else := sprintf("project '%v'", [project])

# --- Matching helpers ---
# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

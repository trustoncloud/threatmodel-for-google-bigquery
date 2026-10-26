package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# 1. Authorized reservation configuration
authorized_editions := {"ENTERPRISE", "ENTERPRISE_PLUS"}

required_ignore_idle_slots := true

max_slot_capacity := 2000

# 2. Authorized assignment configuration
authorized_job_types := {"QUERY", "PIPELINE", "ML_EXTERNAL"}

authorized_assignees := {
    "projects/my-data-project",
    "folders/123456789"
}

# --- Logic ---
# Finding: reservation on an unauthorized edition.
WizPolicy[result] {
    document := input.document[i]
    res := document.resource.google_bigquery_reservation[name]
    not authorized_editions[res.edition]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation",
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("google_bigquery_reservation[%s].edition", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("edition must be one of: %v", [authorized_editions]),
        "keyActualValue": sprintf("edition is '%v'", [object.get(res, "edition", "unset")]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# Finding: idle-slot sharing configured against the requirement.
WizPolicy[result] {
    document := input.document[i]
    res := document.resource.google_bigquery_reservation[name]
    object.get(res, "ignore_idle_slots", false) != required_ignore_idle_slots

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation",
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("google_bigquery_reservation[%s].ignore_idle_slots", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("ignore_idle_slots must be %v", [required_ignore_idle_slots]),
        "keyActualValue": sprintf("ignore_idle_slots is %v", [object.get(res, "ignore_idle_slots", false)]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# Finding: reservation above the slot capacity ceiling.
WizPolicy[result] {
    document := input.document[i]
    res := document.resource.google_bigquery_reservation[name]
    to_number(res.slot_capacity) > max_slot_capacity

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation",
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("google_bigquery_reservation[%s].slot_capacity", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("slot_capacity must not exceed %v", [max_slot_capacity]),
        "keyActualValue": sprintf("slot_capacity is %v", [res.slot_capacity]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# Finding: assignment with an unauthorized job type.
WizPolicy[result] {
    document := input.document[i]
    asg := document.resource.google_bigquery_reservation_assignment[name]
    not authorized_job_types[asg.job_type]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation_assignment",
        "resourceName": terraLib.get_resource_name(asg, name),
        "searchKey": sprintf("google_bigquery_reservation_assignment[%s].job_type", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("job_type must be one of: %v", [authorized_job_types]),
        "keyActualValue": sprintf("job_type is '%v'", [object.get(asg, "job_type", "unset")]),
        "resourceTags": object.get(asg, "labels", {}),
    }
}

# Finding: assignment to an unauthorized assignee.
WizPolicy[result] {
    document := input.document[i]
    asg := document.resource.google_bigquery_reservation_assignment[name]
    not authorized_assignees[asg.assignee]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation_assignment",
        "resourceName": terraLib.get_resource_name(asg, name),
        "searchKey": sprintf("google_bigquery_reservation_assignment[%s].assignee", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("assignee must be one of: %v", [authorized_assignees]),
        "keyActualValue": sprintf("assignee is '%v'", [object.get(asg, "assignee", "unset")]),
        "resourceTags": object.get(asg, "labels", {}),
    }
}

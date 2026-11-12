package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# 1. Authorized reservation configuration
authorized_editions := {"ENTERPRISE", "ENTERPRISE_PLUS"}

required_ignore_idle_slots := true

# The most slots a reservation can reach: its baseline (slot_capacity) plus
# what autoscaling can add (autoscale.max_slots).
max_slot_capacity := 2000

# 2. Authorized assignment configuration
authorized_job_types := {"QUERY", "PIPELINE", "ML_EXTERNAL"}

authorized_assignees := {
    "projects/my-data-project",
    "folders/123456789"
}

# 3. Reservations outside the scanned files that an assignment may target,
# by full name with the project ID. A reservation declared in the same scan
# needs no entry: this rule already checks it.
authorized_reservation_names_by_project_id := {
    "projects/my-admin-project/locations/us/reservations/shared-slots"
}

# --- Helpers ---
# A value written in the resource. A value taken from a variable or another
# resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

# Slots autoscaling can add on top of the baseline. No autoscale block adds
# none.
autoscale_max(res) := n {
    a := terraLib.getValueArrayOrObject(res.autoscale)
    n := to_number(object.get(a, "max_slots", 0))
} else := 0 {
    not res.autoscale
}

reachable_slots(res) := to_number(res.slot_capacity) + autoscale_max(res)

# A capacity the source does not state: a value from a variable or another
# resource, or an autoscale block built by a dynamic block.
capacity_unknown(res) {
    tocm_tf_unresolved(res.slot_capacity)
}

capacity_unknown(res) {
    a := terraLib.getValueArrayOrObject(res.autoscale)
    tocm_tf_unresolved(a.max_slots)
}

# A dynamic block sits under a "dynamic" key, as a list of blocks or as one
# block. What it builds is not in the source as text.
capacity_unknown(res) {
    res.dynamic[_].autoscale
}

capacity_unknown(res) {
    res.dynamic.autoscale
}

# The reservation resource an assignment points at by reference, and the
# attribute it reads. `.id` is the full name of that reservation. `.name` is
# its short name only, so the assignment's own project and location decide
# which reservation it is.
reservation_reference(asg) := {"resource": found[0][1], "attribute": found[0][2]} {
    found := regex.find_all_string_submatch_n(`^\$\{\s*google_bigquery_reservation\.([A-Za-z0-9_-]+)\.(id|name)\s*\}$`, sprintf("%v", [object.get(asg, "reservation", "")]), 1)
    count(found) == 1
}

# The reference resolves to the reservation declared in the same file, or,
# when that file declares none, to the only reservation with that resource
# name in the scan. A scan can hold files from several modules, so a name
# that two other files declare leaves the reference unknown.
referenced_reservation(doc, rname) := res {
    res := input.document[doc].resource.google_bigquery_reservation[rname]
}

referenced_reservation(doc, rname) := res {
    not input.document[doc].resource.google_bigquery_reservation[rname]
    found := [r | r := input.document[_].resource.google_bigquery_reservation[rname]]
    count(found) == 1
    res := found[0]
}

# The full name of a reservation written as text: either the whole name, or
# a bare name with a literal project and location on the assignment.
reservation_literal_name(asg) := asg.reservation {
    is_literal(asg.reservation)
    tocm_gcp_name_ok(asg.reservation)
}

reservation_literal_name(asg) := name {
    is_literal(asg.reservation)
    not tocm_gcp_name_ok(asg.reservation)
    is_literal(asg.project)
    is_literal(asg.location)
    name := tocm_gcp_name(asg.project, asg.location, "reservations", asg.reservation)
}

# Reservations in the scan that state their project, location and name.
declared_reservation_names := {n |
    res := input.document[_].resource.google_bigquery_reservation[_]
    is_literal(res.project)
    is_literal(res.location)
    is_literal(res.name)
    n := tocm_gcp_name(res.project, res.location, "reservations", res.name)
}

# The provider configuration a resource uses. Leaving `provider` out is the
# same as naming the default one.
provider_configuration(resource) := "google" {
    default_provider_values[object.get(resource, "provider", "")]
} else := object.get(resource, "provider", "")

default_provider_values := {"", "google", "${google}"}

# Two resources are in the same project when both state the same project, or
# both leave it to the same provider configuration.
same_project(a, b) {
    is_literal(a.project)
    is_literal(b.project)
    lower(a.project) == lower(b.project)
}

same_project(a, b) {
    object.get(a, "project", "") == ""
    object.get(b, "project", "") == ""
    provider_configuration(a) == provider_configuration(b)
}

same_location(a, b) {
    is_literal(a.location)
    is_literal(b.location)
    lower(a.location) == lower(b.location)
}

# The full name an assignment targets when it is written as text, or built
# from a referenced reservation's short name and the assignment's own project
# and location.
reservation_target_name(asg, doc) := reservation_literal_name(asg)

reservation_target_name(asg, doc) := name {
    ref := reservation_reference(asg)
    ref.attribute == "name"
    short := referenced_reservation(doc, ref.resource).name
    is_literal(short)
    is_literal(asg.project)
    is_literal(asg.location)
    name := tocm_gcp_name(asg.project, asg.location, "reservations", short)
}

# The assignment targets a reservation this rule checks (one in the scan) or
# one on the approved list.
reservation_known(asg, doc) {
    ref := reservation_reference(asg)
    ref.attribute == "id"
    referenced_reservation(doc, ref.resource)
}

reservation_known(asg, doc) {
    ref := reservation_reference(asg)
    ref.attribute == "name"
    res := referenced_reservation(doc, ref.resource)
    same_project(asg, res)
    same_location(asg, res)
}

reservation_known(asg, doc) {
    tocm_gcp_name_allowed(reservation_target_name(asg, doc), declared_reservation_names)
}

reservation_known(asg, doc) {
    tocm_gcp_name_allowed(reservation_target_name(asg, doc), authorized_reservation_names_by_project_id)
}

reservation_description(asg, doc) := sprintf("reservation points at google_bigquery_reservation.%s, which this file does not declare and which is not the only reservation with that name in the scan", [reservation_reference(asg).resource]) {
    not referenced_reservation(doc, reservation_reference(asg).resource)
} else := sprintf("reservation '%v' is neither declared in this scan nor an approved reservation", [reservation_target_name(asg, doc)]) {
    reservation_target_name(asg, doc)
} else := sprintf("reservation takes the short name of google_bigquery_reservation.%s, and the assignment's project and location do not tie it to that reservation or to a full name", [reservation_reference(asg).resource]) {
    reservation_reference(asg).attribute == "name"
} else := sprintf("reservation is '%v', which is not known until apply", [asg.reservation]) {
    tocm_tf_unresolved(asg.reservation)
} else := sprintf("reservation is '%v' with no literal project and location, so it cannot be matched", [object.get(asg, "reservation", "unset")])

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

# Finding: baseline within the ceiling, but autoscaling can take the
# reservation above it.
WizPolicy[result] {
    document := input.document[i]
    res := document.resource.google_bigquery_reservation[name]
    to_number(res.slot_capacity) <= max_slot_capacity
    reachable_slots(res) > max_slot_capacity

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation",
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("google_bigquery_reservation[%s].autoscale.max_slots", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("slot_capacity plus autoscale.max_slots must not exceed %v", [max_slot_capacity]),
        "keyActualValue": sprintf("slot_capacity %v plus autoscale.max_slots %v can reach %v slots", [res.slot_capacity, autoscale_max(res), reachable_slots(res)]),
        "resourceTags": object.get(res, "labels", {}),
    }
}

# Finding: capacity the source does not state, so the ceiling cannot be
# checked.
WizPolicy[result] {
    document := input.document[i]
    res := document.resource.google_bigquery_reservation[name]
    capacity_unknown(res)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation",
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("google_bigquery_reservation[%s].slot_capacity", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("slot_capacity and autoscale.max_slots must be written as numbers that together do not exceed %v", [max_slot_capacity]),
        "keyActualValue": "slot_capacity or autoscale.max_slots is not known until apply",
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

# Finding: assignment to a reservation that is neither checked in this scan
# nor on the approved list.
WizPolicy[result] {
    document := input.document[i]
    asg := document.resource.google_bigquery_reservation_assignment[name]
    not reservation_known(asg, i)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_reservation_assignment",
        "resourceName": terraLib.get_resource_name(asg, name),
        "searchKey": sprintf("google_bigquery_reservation_assignment[%s].reservation", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("reservation must be a reservation declared in this scan, or one of: %v", [authorized_reservation_names_by_project_id]),
        "keyActualValue": reservation_description(asg, i),
        "resourceTags": object.get(asg, "labels", {}),
    }
}

# --- Matching helpers ---
# --- toc-match begin: gcpname v1 ---
# Relative GCP resource name ("projects/p/locations/l/dataExchanges/x") from
# a relative name, a full name ("//bigquery.googleapis.com/projects/...") or a
# self link ("https://www.googleapis.com/compute/v1/projects/..."). Names
# compare segment by segment, so Compute's global resources
# ("projects/p/global/networks/n"), image families
# (".../global/images/family/f") and uid paths keep their own shape.
tocm_gcp_rel(name) := r {
    is_string(name)
    n := trim_space(name)
    not contains(n, "//")
    r := trim_suffix(n, "/")
}

tocm_gcp_rel(name) := r {
    is_string(name)
    n := trim_space(name)
    contains(n, "//")
    starts := [i |
        root := ["/projects/", "/organizations/", "/folders/", "/billingAccounts/"][_]
        i := indexof(n, root)
        i >= 0
    ]
    count(starts) > 0
    r := trim_suffix(substring(n, min(starts) + 1, -1), "/")
}

# Segments in order; the id after locations, regions or zones is lowercased
# because surfaces disagree on its case.
tocm_gcp_name_norm(name) := [x |
    s := split(tocm_gcp_rel(name), "/")
    some i
    s[i]
    x := tocm_gcp_seg(s, i)
]

tocm_gcp_seg(s, i) := lower(s[i]) {
    i > 0
    {"locations", "regions", "zones"}[s[i - 1]]
}

tocm_gcp_seg(s, i) := s[i] {
    i == 0
}

tocm_gcp_seg(s, i) := s[i] {
    i > 0
    not {"locations", "regions", "zones"}[s[i - 1]]
}

tocm_gcp_name_ok(name) {
    s := split(tocm_gcp_rel(name), "/")
    count(s) >= 2
    {"projects", "organizations", "folders", "billingAccounts"}[s[0]]
    not tocm_gcp_has_empty(s)
}

tocm_gcp_has_empty(s) {
    s[_] == ""
}

# Two names identify the same resource. A project ID never matches a project
# number: configure each surface the way it reports names (Analytics Hub
# cloud payloads carry the project number).
tocm_gcp_name_equal(a, b) {
    tocm_gcp_name_ok(a)
    tocm_gcp_name_ok(b)
    tocm_gcp_name_norm(a) == tocm_gcp_name_norm(b)
}

tocm_gcp_name_allowed(name, allowed) {
    tocm_gcp_name_equal(name, allowed[_])
}

# Relative name from Terraform arguments, for comparing with cloud names.
tocm_gcp_name(project, location, collection, id) := sprintf("projects/%s/locations/%s/%s/%s", [project, lower(location), collection, id])
# --- toc-match end: gcpname v1 ---

# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

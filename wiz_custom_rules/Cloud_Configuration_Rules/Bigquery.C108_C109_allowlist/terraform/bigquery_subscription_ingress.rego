package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Terraform names a project by its ID, so write each name with the project
# ID of the publisher.
# 1. Data exchanges your projects may subscribe to, by full resource name.
#    An entry approves every listing in that exchange.
authorized_source_exchange_names_by_project_id := {
    "projects/partner-project/locations/us/dataExchanges/governed_partner_exchange"
}

# 2. Single listings your projects may subscribe to, by full resource name,
#    in exchanges that are not approved as a whole.
authorized_source_listing_names_by_project_id := {
    "projects/my-project/locations/us/dataExchanges/internal_reference_data/listings/public_holidays"
}

# 3. Projects that may hold the linked dataset a subscription creates.
#    Keep in sync with the cloud matcher.
authorized_subscriber_project_ids := {
    "my-project"
}

# --- Helpers ---
# A value written in the resource itself. A value taken from a variable, a
# local or another resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

# Full name of the exchange the subscription targets, when the resource
# states its project, location and exchange ID. The provider's default
# project is not in the source, so a subscription without a project of its
# own has no full name.
exchange_name(sub) := n {
    is_literal(sub.project)
    is_literal(sub.location)
    is_literal(sub.data_exchange_id)
    n := tocm_gcp_name(sub.project, sub.location, "dataExchanges", sub.data_exchange_id)
}

listing_name(sub) := n {
    is_literal(sub.listing_id)
    n := sprintf("%s/listings/%s", [exchange_name(sub), sub.listing_id])
}

source_authorized(sub) {
    tocm_gcp_name_allowed(exchange_name(sub), authorized_source_exchange_names_by_project_id)
}

source_authorized(sub) {
    tocm_gcp_name_allowed(listing_name(sub), authorized_source_listing_names_by_project_id)
}

source_description(sub) := sprintf("subscription targets listing '%v'", [listing_name(sub)]) {
    listing_name(sub)
} else := sprintf("subscription targets exchange '%v' and a listing that is not a literal value", [exchange_name(sub)]) {
    exchange_name(sub)
} else := "the listing cannot be matched: project, location and data_exchange_id must be literal values"

# Project of the linked dataset, when the resource states one.
destination_reference(sub) := ref {
    dest := terraLib.getValueArrayOrObject(sub.destination_dataset)
    ref := terraLib.getValueArrayOrObject(dest.dataset_reference)
}

destination_project_stated(sub) {
    object.get(destination_reference(sub), "project_id", "") != ""
}

destination_authorized(sub) {
    project := destination_reference(sub).project_id
    is_literal(project)
    authorized_subscriber_project_ids[project]
}

# --- Logic ---
# Finding: subscription to a listing outside the approved exchanges and listings.
WizPolicy[result] {
    document := input.document[i]
    sub := document.resource.google_bigquery_analytics_hub_listing_subscription[name]
    not source_authorized(sub)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing_subscription",
        "resourceName": terraLib.get_resource_name(sub, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing_subscription[%s].data_exchange_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "a subscription must target an exchange in authorized_source_exchange_names_by_project_id or a listing in authorized_source_listing_names_by_project_id, matched on project, location, exchange and listing together",
        "keyActualValue": source_description(sub),
        "resourceTags": object.get(sub, "labels", {}),
    }
}

# Finding: linked dataset created in a project that may not subscribe.
WizPolicy[result] {
    document := input.document[i]
    sub := document.resource.google_bigquery_analytics_hub_listing_subscription[name]
    destination_project_stated(sub)
    not destination_authorized(sub)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing_subscription",
        "resourceName": terraLib.get_resource_name(sub, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing_subscription[%s].destination_dataset.dataset_reference.project_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("the linked dataset must be created in a project listed in authorized_subscriber_project_ids: %v", [authorized_subscriber_project_ids]),
        "keyActualValue": sprintf("the linked dataset is created in project '%v'", [destination_reference(sub).project_id]),
        "resourceTags": object.get(sub, "labels", {}),
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

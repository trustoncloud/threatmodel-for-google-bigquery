package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# 1. Listings allowed to have data export enabled (e.g. reference data),
#    keyed by the listing_id declared on the resource.
authorized_exportable_listing_ids := {
    "public_holidays",
    "zip_codes"
}

# 2. Private exchanges declared outside the scanned files, as
#    projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>.
#    A listing that leaves out discovery_type takes it from its exchange, so
#    an exchange the scan cannot read must be listed here.
authorized_private_exchange_names_by_project_id := {
    "projects/my-project/locations/us/dataExchanges/internal_analytics"
}

# 3. Governance requirements
require_description := true

require_documentation := true

# --- Helpers ---
listing_export_restricted(l) {
    cfg := terraLib.getValueArrayOrObject(l.restricted_export_config)
    cfg.enabled == true
}

# Restricted export governs a shared dataset. A listing that shares a Pub/Sub
# topic and no dataset has nothing for it to restrict. A listing with neither
# block written out (a source built by a dynamic block) is held to the rule.
shares_topic_only(l) {
    l.pubsub_topic
    not l.bigquery_dataset
}

# A value written in the resource itself. A value taken from a variable, a
# local or another resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

# A listing with no discovery type of its own takes the one of its exchange.
takes_exchange_discovery(l) {
    d := object.get(l, "discovery_type", "")
    d != "DISCOVERY_TYPE_PUBLIC"
    d != "DISCOVERY_TYPE_PRIVATE"
    not tocm_tf_unresolved(d)
}

# The exchange a listing names by a reference to an exchange resource: the
# one declared in the same file, or, when that file declares none, the only
# exchange resource with that name in the scan. A scan can hold files from
# several modules, so a name that two other files declare stays unknown.
exchange_reference(l) := exname {
    found := regex.find_all_string_submatch_n(`^\$\{\s*google_bigquery_analytics_hub_data_exchange\.([A-Za-z0-9_-]+)\.data_exchange_id\s*\}$`, sprintf("%v", [object.get(l, "data_exchange_id", "")]), 1)
    count(found) == 1
    exname := found[0][1]
}

referenced_exchange(doc, exname) := ex {
    ex := input.document[doc].resource.google_bigquery_analytics_hub_data_exchange[exname]
}

referenced_exchange(doc, exname) := ex {
    not input.document[doc].resource.google_bigquery_analytics_hub_data_exchange[exname]
    found := [e | e := input.document[_].resource.google_bigquery_analytics_hub_data_exchange[exname]]
    count(found) == 1
    ex := found[0]
}

# The ID of the exchange a listing names: written in the listing, or read
# from the exchange resource it refers to. A reference gives the ID only, so
# the listing's own project and location still decide which exchange it is.
listing_exchange_id(doc, l) := l.data_exchange_id {
    is_literal(l.data_exchange_id)
}

listing_exchange_id(doc, l) := id {
    id := referenced_exchange(doc, exchange_reference(l)).data_exchange_id
    is_literal(id)
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

other_project(a, b) {
    is_literal(a.project)
    is_literal(b.project)
    lower(a.project) != lower(b.project)
}

same_location(a, b) {
    is_literal(a.location)
    is_literal(b.location)
    lower(a.location) == lower(b.location)
}

other_location(a, b) {
    is_literal(a.location)
    is_literal(b.location)
    lower(a.location) != lower(b.location)
}

# The exchange of a listing has the same ID, project and location.
is_exchange_of(doc, l, ex) {
    ex.data_exchange_id == listing_exchange_id(doc, l)
    same_project(l, ex)
    same_location(l, ex)
}

# An exchange with the same ID that the source does not place in another
# project or location: it may be the exchange of the listing.
may_be_exchange_of(doc, l, ex) {
    ex.data_exchange_id == listing_exchange_id(doc, l)
    not other_project(l, ex)
    not other_location(l, ex)
}

exchanges_in_file(doc, l) := [ex |
    ex := input.document[doc].resource.google_bigquery_analytics_hub_data_exchange[_]
    is_exchange_of(doc, l, ex)
]

exchanges_in_scan(doc, l) := [ex |
    ex := input.document[_].resource.google_bigquery_analytics_hub_data_exchange[_]
    is_exchange_of(doc, l, ex)
]

possible_exchanges(doc, l) := [ex |
    ex := input.document[_].resource.google_bigquery_analytics_hub_data_exchange[_]
    may_be_exchange_of(doc, l, ex)
]

# The exchange of a listing, when the scan settles which one it is: the one
# in the same file, or, when that file declares none, the only one in the scan.
exchange_of(doc, l) := ex {
    found := exchanges_in_file(doc, l)
    count(found) == 1
    ex := found[0]
}

exchange_of(doc, l) := ex {
    count(exchanges_in_file(doc, l)) == 0
    found := exchanges_in_scan(doc, l)
    count(found) == 1
    ex := found[0]
}

# An exchange named by an ID that no file in the scan can be declaring. Its
# discovery type cannot be read, so it must be on the list of private
# exchanges, matched on project, location and ID together.
exchange_outside_scan(doc, l) {
    listing_exchange_id(doc, l)
    count(possible_exchanges(doc, l)) == 0
}

listing_exchange_name(doc, l) := tocm_gcp_name(l.project, l.location, "dataExchanges", listing_exchange_id(doc, l)) {
    is_literal(l.project)
    is_literal(l.location)
}

exchange_listed_private(doc, l) {
    tocm_gcp_name_allowed(listing_exchange_name(doc, l), authorized_private_exchange_names_by_project_id)
}

# One discovery problem per listing, at most.
discovery_problem(doc, l) := "discovery_type is set from a value that is not known until apply" {
    tocm_tf_unresolved(object.get(l, "discovery_type", ""))
} else := sprintf("discovery_type is left out and exchange '%v' is publicly discoverable", [exchange_of(doc, l).data_exchange_id]) {
    takes_exchange_discovery(l)
    exchange_of(doc, l).discovery_type == "DISCOVERY_TYPE_PUBLIC"
} else := sprintf("discovery_type is left out and exchange '%v' sets its own from a value that is not known until apply", [exchange_of(doc, l).data_exchange_id]) {
    takes_exchange_discovery(l)
    tocm_tf_unresolved(object.get(exchange_of(doc, l), "discovery_type", ""))
} else := "discovery_type is left out and the exchange of this listing cannot be read from the source" {
    takes_exchange_discovery(l)
    not exchange_of(doc, l)
    not exchange_outside_scan(doc, l)
} else := sprintf("discovery_type is left out and exchange '%v' is neither declared in the scanned files nor listed in authorized_private_exchange_names_by_project_id", [listing_exchange_name(doc, l)]) {
    takes_exchange_discovery(l)
    exchange_outside_scan(doc, l)
    not exchange_listed_private(doc, l)
    listing_exchange_name(doc, l)
} else := "discovery_type is left out, the exchange is not declared in the scanned files, and the listing states no literal project and location to match it to authorized_private_exchange_names_by_project_id" {
    takes_exchange_discovery(l)
    exchange_outside_scan(doc, l)
    not listing_exchange_name(doc, l)
}

# --- Logic ---
# Finding: listing published to the marketplace (public discovery).
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    l.discovery_type == "DISCOVERY_TYPE_PUBLIC"

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].discovery_type", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "listings must not use public discovery",
        "keyActualValue": sprintf("listing '%v' is publicly discoverable", [l.listing_id]),
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: public discovery taken from the exchange, or a discovery type the
# source does not show.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    problem := discovery_problem(i, l)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].data_exchange_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "a listing must not be publicly discoverable, by its own discovery_type or by the one it takes from its exchange. IAM grants on the exchange, and an exchange that no file in the scan declares, are not read",
        "keyActualValue": problem,
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: data export not restricted and listing not allowlisted.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    not shares_topic_only(l)
    not listing_export_restricted(l)
    not authorized_exportable_listing_ids[l.listing_id]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].restricted_export_config.enabled", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "restricted_export_config.enabled must be true unless the listing is allowlisted as exportable",
        "keyActualValue": sprintf("listing '%v' allows data export", [l.listing_id]),
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: missing description (governance).
WizPolicy[result] {
    require_description
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    object.get(l, "description", "") == ""

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].description", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "listings must carry a description",
        "keyActualValue": "description is not set",
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: missing documentation (governance).
WizPolicy[result] {
    require_documentation
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    object.get(l, "documentation", "") == ""

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].documentation", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "listings must carry documentation",
        "keyActualValue": "documentation is not set",
        "resourceTags": object.get(l, "labels", {}),
    }
}

# --- Matching helpers ---
# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

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

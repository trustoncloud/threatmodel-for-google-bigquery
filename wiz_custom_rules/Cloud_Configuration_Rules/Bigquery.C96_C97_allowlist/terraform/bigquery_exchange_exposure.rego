package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Exchanges authorized to be published to the Analytics Hub marketplace
# (public discovery), by full resource name. Terraform names the project by
# its ID, so write each name with the project ID; the cloud matcher's list
# carries the project number for the same exchange.
authorized_public_exchange_names_by_project_id := {
    "projects/my-project/locations/us/dataExchanges/official_public_dataset"
}

# --- Helpers ---
# A value written in the resource itself. A value taken from a variable, a
# local or another resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

# Full name of the exchange, when the resource states its project, location
# and ID. The provider's default project is not in the plan, so an exchange
# without a project of its own has no name to compare.
exchange_name(ex) := n {
    is_literal(ex.project)
    is_literal(ex.location)
    is_literal(ex.data_exchange_id)
    n := tocm_gcp_name(ex.project, ex.location, "dataExchanges", ex.data_exchange_id)
}

publication_authorized(ex) {
    tocm_gcp_name_allowed(exchange_name(ex), authorized_public_exchange_names_by_project_id)
}

published_as(ex) := sprintf("exchange '%v' is published (DISCOVERY_TYPE_PUBLIC) and is not on the authorized list", [exchange_name(ex)]) {
    exchange_name(ex)
} else := sprintf("exchange '%v' is published (DISCOVERY_TYPE_PUBLIC) and does not state its project, location and ID as literal values, so it cannot be matched to the authorized list", [object.get(ex, "data_exchange_id", "")])

# --- Logic ---
# Finding: exchange published to the marketplace without authorization.
# Absent discovery_type means the exchange is not published.
WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    ex.discovery_type == "DISCOVERY_TYPE_PUBLIC"
    not publication_authorized(ex)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].discovery_type", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "an exchange may be published only when its project, location and data_exchange_id together match an entry in authorized_public_exchange_names_by_project_id",
        "keyActualValue": published_as(ex),
        "resourceTags": object.get(ex, "labels", {}),
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

package wiz

# --- Configuration ---
# 1. Authorized External Sources (Allowlist)
# A list of Regex patterns matched against "projects/{projectNumber}/datasets/{datasetId}".
# NOTE: the API reports the source project as a project NUMBER, not a project ID.
# Keep the "^" and "$" anchors so a pattern cannot match a longer name.
authorized_source_dataset_patterns := {
    # Example: Allow a specific partner project (by project number)
    "^projects/123456789012/datasets/sales_data_shared$",

    # Example: Allow any dataset from an authorized project number
    "^projects/987654321098/datasets/.*$"
}

# 2. (Optional) Internal Project Exclusion
# Auto-pass links from your own project numbers.
internal_project_pattern := "^projects/(111111111111|222222222222)/datasets/.*$"

# 3. Projects that may hold a linked dataset, by project ID.
#    Keep in sync with the Terraform matcher.
authorized_subscriber_project_ids := {
    "my-project"
}

# 4. Data exchanges your projects may subscribe to, by full resource name with
#    the project NUMBER of the publisher. An entry approves every listing in
#    that exchange. Read from subscriptions.
authorized_source_exchange_names := {
    "projects/123456789012/locations/us/dataExchanges/governed_partner_exchange"
}

# 5. Single listings your projects may subscribe to, by full resource name with
#    the project NUMBER of the publisher, in exchanges that are not approved as
#    a whole. Read from subscriptions.
authorized_source_listing_names := {
    "projects/111111111111/locations/us/dataExchanges/internal_reference_data/listings/public_holidays"
}

# 6. Projects that may hold a linked dataset, by project NUMBER. Read only when
#    a subscription does not state the project ID of its destination dataset:
#    the linked dataset it names then carries the project number.
authorized_subscriber_project_numbers := {
    "111111111111"
}

# --- Logic ---
default result := "pass"

# 1. Identify Linked Datasets (Subscriptions)
# A dataset is a subscription when it carries 'linkedDatasetSource' or its
# link state is LINKED. sourceDataset is a reference object
# {projectId, datasetId}, where projectId carries the source project NUMBER.
is_linked_dataset {
    input.linkedDatasetSource
}

is_linked_dataset {
    input.linkedDatasetMetadata.linkState == "LINKED"
}

get_source_dataset = src {
    ref := input.linkedDatasetSource.sourceDataset
    is_string(ref.datasetId)
    ref.datasetId != ""
    project := sprintf("%v", [ref.projectId])
    project != ""
    src := sprintf("projects/%v/datasets/%v", [project, ref.datasetId])
}

# Helper: Check if Source is Allowed
is_source_allowed(src) {
    # Check Allowlist
    pattern := authorized_source_dataset_patterns[_]
    regex.match(pattern, src)
} else {
    # Check Internal Pattern (Auto-allow internal links)
    regex.match(internal_project_pattern, src)
}

# Failure: Subscription to an Unauthorized Source
fail_unauthorized_subscription {
    src := get_source_dataset

    # Fail if the source matches NONE of the allowed patterns
    not is_source_allowed(src)
}

# Failure: Linked dataset whose source the payload does not state
fail_source_unknown {
    is_linked_dataset
    not get_source_dataset
}

# Failure: Linked dataset in a project that may not subscribe
fail_unauthorized_subscriber_project {
    is_linked_dataset
    not authorized_subscriber_project_ids[input.datasetReference.projectId]
}

dataset_issues[msg] {
    fail_unauthorized_subscription
    msg := sprintf("source dataset '%v' is not an authorized source", [get_source_dataset])
}

dataset_issues[msg] {
    fail_source_unknown
    msg := "the source dataset of this linked dataset cannot be read"
}

dataset_issues[msg] {
    fail_unauthorized_subscriber_project
    msg := sprintf("project '%v' is not approved to hold linked datasets", [object.get(input.datasetReference, "projectId", "")])
}

# 2. Subscriptions
# A subscription sits in the subscriber's project, named with its project ID:
# projects/<project-id>/locations/<location>/subscriptions/<id>. It names its
# source with the publisher's project NUMBER.
is_subscription {
    regex.match(`^projects/[^/]+/locations/[^/]+/subscriptions/[^/]+$`, object.get(input, "name", ""))
}

# state is an integer: 1 active, 2 stale, 3 inactive. An inactive subscription
# was cancelled or revoked and gives no access, so it is not judged.
subscription_inactive {
    input.state == 3
}

subscription_project := split(input.name, "/")[1]

source_listing := l {
    l := input.ResourceName.Listing
    is_string(l)
    l != ""
}

source_exchange := x {
    x := input.ResourceName.DataExchange
    is_string(x)
    x != ""
}

# The exchange that holds a listing, from the listing's own name.
exchange_of_listing(l) := m[1] {
    m := regex.find_all_string_submatch_n(`^(projects/[^/]+/locations/[^/]+/dataExchanges/[^/]+)/listings/[^/]+$`, l, 1)[0]
}

subscription_source_approved {
    tocm_gcp_name_allowed(source_listing, authorized_source_listing_names)
}

subscription_source_approved {
    tocm_gcp_name_allowed(exchange_of_listing(source_listing), authorized_source_exchange_names)
}

subscription_source_approved {
    not source_listing
    tocm_gcp_name_allowed(source_exchange, authorized_source_exchange_names)
}

subscription_source := s {
    s := source_listing
} else := s {
    s := source_exchange
}

# A subscription to a Pub/Sub listing (resource_type 2) links no dataset.
shares_topic {
    input.resource_type == 2
}

# The project ID of the destination dataset, when the subscription states it.
# Left out, null at any level or not text, it is "" and the linked dataset
# is read instead.
destination_project := p {
    p := input.destination_dataset.dataset_reference.project_id
    is_string(p)
} else := ""

# Otherwise the linked datasets it names, as projects/<number>/datasets/<id>.
linked_datasets[d] {
    d := input.linked_resources[_].Reference.LinkedDataset
    is_string(d)
    d != ""
}

linked_dataset_project(d) := m[1] {
    m := regex.find_all_string_submatch_n(`^projects/([^/]+)/datasets/[^/]+$`, d, 1)[0]
}

subscription_issues[msg] {
    not subscription_source
    msg := "the subscription does not state the listing or exchange it is to"
}

subscription_issues[msg] {
    subscription_source
    not subscription_source_approved
    msg := sprintf("'%v' is not an authorized source", [subscription_source])
}

subscription_issues[msg] {
    not authorized_subscriber_project_ids[subscription_project]
    msg := sprintf("project '%v' is not approved to subscribe", [subscription_project])
}

subscription_issues[msg] {
    not shares_topic
    destination_project != ""
    not authorized_subscriber_project_ids[destination_project]
    msg := sprintf("the destination dataset sits in project '%v', which is not approved to hold linked datasets", [destination_project])
}

subscription_issues[msg] {
    not shares_topic
    destination_project == ""
    d := linked_datasets[_]
    p := linked_dataset_project(d)
    not authorized_subscriber_project_numbers[p]
    msg := sprintf("the linked dataset '%v' sits in a project that is not approved to hold linked datasets", [d])
}

subscription_issues[msg] {
    not shares_topic
    destination_project == ""
    d := linked_datasets[_]
    not linked_dataset_project(d)
    msg := sprintf("the linked dataset name '%v' does not show its project", [d])
}

subscription_issues[msg] {
    not shares_topic
    destination_project == ""
    count(linked_datasets) == 0
    msg := "the subscription states no destination dataset and names no linked dataset"
}

issues[msg] {
    input.datasetReference
    msg := dataset_issues[_]
}

issues[msg] {
    is_subscription
    not subscription_inactive
    msg := subscription_issues[_]
}

# --- Aggregation ---
result := "skip" {
    not input.datasetReference
    not is_subscription
} else := "skip" {
    is_subscription
    subscription_inactive
} else := "fail" {
    count(issues) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Subscription: %v", [concat("; ", sort(issues))]) {
    count(issues) > 0
    is_subscription
} else := sprintf("Linked dataset: %v", [concat("; ", sort(issues))]) {
    count(issues) > 0
} else := "The subscription was cancelled or revoked and gives no access" {
    is_subscription
    subscription_inactive
} else := "Subscription source and project are authorized" {
    is_subscription
} else := "Subscription source and project are authorized (or dataset is native)"

expectedConfiguration := "A subscription must be to a listing or exchange listed in authorized_source_listing_names or authorized_source_exchange_names (full names with the publisher's project number), and sit in a project listed in authorized_subscriber_project_ids, as must the dataset it links (or, when only the linked dataset names it, a project in authorized_subscriber_project_numbers). Only active and stale subscriptions are judged." {
    is_subscription
} else := "Linked datasets must point to an authorized source dataset and sit in a project listed in authorized_subscriber_project_ids. The dataset does not carry the listing or exchange it was subscribed through; the rule on subscriptions checks those."

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

package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher.
authorized_data_source_ids := {
    "google_cloud_storage",
    "scheduled_query"
}

# Destination datasets, each with the project that holds it. Terraform names
# the project by its ID (the cloud matcher's list uses the project number).
# A transfer writes to a dataset in its own project, so the resource must set
# project to a literal value to be matched.
authorized_destination_datasets_by_project_id := {
    "projects/my-project/datasets/raw_ingestion_zone",
    "projects/my-project/datasets/my_governed_dataset"
}

# Identities authorized to RUN transfers. In IaC this is enforceable at
# write time through service_account_name; unset means the applying user's
# identity, which the cloud matcher verifies at runtime via owner_info.
authorized_transfer_identities := {
    "etl-loader@my-project.iam.gserviceaccount.com",
    "backup-admin@my-project.iam.gserviceaccount.com"
}

# Cloud Storage locations a transfer may read. A bucket ("gs://bucket")
# approves everything in it; a folder ("gs://bucket/folder/") approves only
# what is inside it. Bucket names match exactly, never by prefix.
authorized_gcs_paths := {
    "gs://trusted-corp-landing",
    "gs://trusted-corp-archive/inbound/"
}

# --- Helpers ---
# A value written in the resource. A value taken from a variable or another
# resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

# The destination dataset ID: written in the resource, or read from the
# google_bigquery_dataset in the plan that destination_dataset_id points to.
destination_dataset_ids(tc) := {id |
    id := tc.destination_dataset_id
    is_literal(id)
}

referenced_dataset_ids(tc, doc) := {id |
    found := regex.find_all_string_submatch_n(`^\$\{\s*google_bigquery_dataset\.([A-Za-z0-9_-]+)\.dataset_id\s*\}$`, sprintf("%v", [object.get(tc, "destination_dataset_id", "")]), 1)
    count(found) == 1
    id := referenced_dataset(doc, found[0][1]).dataset_id
    is_literal(id)
}

# The dataset resource a reference names: the one declared in the same file,
# or, when that file declares none, the only dataset resource with that name
# in the scan. A scan can hold files from several modules, so a name that two
# other files declare leaves the reference unknown.
referenced_dataset(doc, dsname) := ds {
    ds := input.document[doc].resource.google_bigquery_dataset[dsname]
}

referenced_dataset(doc, dsname) := ds {
    not input.document[doc].resource.google_bigquery_dataset[dsname]
    found := [d | d := input.document[_].resource.google_bigquery_dataset[dsname]]
    count(found) == 1
    ds := found[0]
}

destination_names(tc, doc) := {name |
    is_literal(tc.project)
    id := (destination_dataset_ids(tc) | referenced_dataset_ids(tc, doc))[_]
    name := sprintf("projects/%s/datasets/%s", [tc.project, id])
}

destination_authorized(tc, doc) {
    names := destination_names(tc, doc)
    count(names) == 1
    tocm_gcp_name_allowed(names[_], authorized_destination_datasets_by_project_id)
}

destination_description(tc, doc) := sprintf("destination is '%v'", [concat(", ", sort(destination_names(tc, doc)))]) {
    count(destination_names(tc, doc)) > 0
} else := "project is not written in the resource, so the destination cannot be matched" {
    not is_literal(object.get(tc, "project", ""))
} else := sprintf("destination_dataset_id '%v' cannot be read from the plan", [object.get(tc, "destination_dataset_id", "unset")])

transfer_params(tc) := params {
    params := terraLib.getValueArrayOrObject(tc.params)
    is_object(params)
}

gcs_path_authorized(tc) {
    tocm_gcs_allowed(transfer_params(tc).data_path_template, authorized_gcs_paths)
}

# A flag is on when it is the boolean true or the string "true".
flag_is_true(v) {
    lower(sprintf("%v", [v])) == "true"
}

# --- Logic ---
# Finding: unauthorized data source.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    not authorized_data_source_ids[tc.data_source_id]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].data_source_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("data_source_id must be one of: %v", [authorized_data_source_ids]),
        "keyActualValue": sprintf("data_source_id is '%v'", [object.get(tc, "data_source_id", "unset")]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: destination project and dataset not approved together.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    not destination_authorized(tc, i)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].destination_dataset_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("project and destination_dataset_id together must name one of: %v", [authorized_destination_datasets_by_project_id]),
        "keyActualValue": destination_description(tc, i),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: transfer declared to run as an unauthorized service account.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    sa := object.get(tc, "service_account_name", "")
    sa != ""
    not tocm_email_allowed(sa, authorized_transfer_identities, [])

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].service_account_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("service_account_name must be one of: %v", [authorized_transfer_identities]),
        "keyActualValue": sprintf("service_account_name is '%v'", [sa]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: GCS transfer reading outside the approved buckets and folders.
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    tc.data_source_id == "google_cloud_storage"
    not gcs_path_authorized(tc)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].params.data_path_template", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("data_path_template must sit in an approved bucket or folder: %v", [authorized_gcs_paths]),
        "keyActualValue": sprintf("data_path_template is '%v'", [object.get(object.get(tc, "params", {}), "data_path_template", "unset")]),
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# Finding: GCS transfer deleting source files (destructive).
WizPolicy[result] {
    document := input.document[i]
    tc := document.resource.google_bigquery_data_transfer_config[name]
    tc.data_source_id == "google_cloud_storage"
    flag_is_true(transfer_params(tc).delete_source_files)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_data_transfer_config",
        "resourceName": terraLib.get_resource_name(tc, name),
        "searchKey": sprintf("google_bigquery_data_transfer_config[%s].params.delete_source_files", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "delete_source_files must not be enabled",
        "keyActualValue": "transfer deletes source files after load",
        "resourceTags": object.get(tc, "labels", {}),
    }
}

# --- Matching helpers ---
# --- toc-match begin: email v1 ---
# Lowercased domain of an email with exactly one "@" and a non-empty local part.
tocm_email_domain(email) := d {
    is_string(email)
    parts := split(lower(trim_space(email)), "@")
    count(parts) == 2
    parts[0] != ""
    d := trim_suffix(parts[1], ".")
    d != ""
}

tocm_is_sa_domain(d) {
    d == "gserviceaccount.com"
}

tocm_is_sa_domain(d) {
    endswith(d, ".gserviceaccount.com")
}

# A domain matches an entry only by equality. An entry "*.corp.com" admits
# subdomains of corp.com across a "." boundary, never corp.com itself, so list
# both when both are wanted. Service-account domains never match a domain
# entry; service accounts go through tocm_sa_allowed.
tocm_domain_allowed(domain, allowed) {
    is_string(domain)
    d := lower(trim_suffix(trim_space(domain), "."))
    not tocm_is_sa_domain(d)
    entry := lower(trim_space(allowed[_]))
    not startswith(entry, "*.")
    d == entry
}

tocm_domain_allowed(domain, allowed) {
    is_string(domain)
    d := lower(trim_suffix(trim_space(domain), "."))
    not tocm_is_sa_domain(d)
    entry := lower(trim_space(allowed[_]))
    startswith(entry, "*.")
    suffix := substring(entry, 1, -1)
    count(d) > count(suffix)
    endswith(d, suffix)
}

# A user or group email: listed exactly, or its domain is allowed.
tocm_email_allowed(email, allowed_emails, _) {
    is_string(email)
    lower(trim_space(email)) == lower(trim_space(allowed_emails[_]))
}

tocm_email_allowed(email, _, allowed_domains) {
    tocm_domain_allowed(tocm_email_domain(email), allowed_domains)
}

tocm_sa_email(sa) := e {
    is_string(sa)
    e := lower(trim_prefix(trim_space(sa), "serviceAccount:"))
}

# Project ID of a user-managed (name@PROJECT_ID.iam.gserviceaccount.com) or
# App Engine default (PROJECT_ID@appspot.gserviceaccount.com) service account.
tocm_sa_project_id(sa) := p {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    parts[0] != ""
    endswith(parts[1], ".iam.gserviceaccount.com")
    p := trim_suffix(parts[1], ".iam.gserviceaccount.com")
    regex.match(`^[a-z][a-z0-9-]{4,28}[a-z0-9]$`, p)
}

tocm_sa_project_id(sa) := p {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    parts[1] == "appspot.gserviceaccount.com"
    p := parts[0]
    regex.match(`^[a-z][a-z0-9-]{4,28}[a-z0-9]$`, p)
}

# Project number of the Compute Engine default, Google APIs and legacy Cloud
# Build accounts, whose domains only Google can issue. Service agents
# (service-N@gcp-sa-*.iam.gserviceaccount.com and similar) are not read here:
# their shapes vary and a user-managed account can imitate them, so list them
# by exact email.
tocm_sa_project_number(sa) := n {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    parts[1] == "developer.gserviceaccount.com"
    endswith(parts[0], "-compute")
    n := trim_suffix(parts[0], "-compute")
    regex.match(`^[0-9]+$`, n)
}

tocm_sa_project_number(sa) := n {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    {"cloudservices.gserviceaccount.com", "cloudbuild.gserviceaccount.com"}[parts[1]]
    n := parts[0]
    regex.match(`^[0-9]+$`, n)
}

# A service account: listed exactly, or its project ID or number is allowed.
tocm_sa_allowed(sa, allowed_sas, _, _) {
    tocm_sa_email(sa) == tocm_sa_email(allowed_sas[_])
}

tocm_sa_allowed(sa, _, allowed_project_ids, _) {
    tocm_sa_project_id(sa) == lower(trim_space(allowed_project_ids[_]))
}

tocm_sa_allowed(sa, _, _, allowed_project_numbers) {
    tocm_sa_project_number(sa) == sprintf("%v", [allowed_project_numbers[_]])
}

# An IAM member string ("user:a@corp.com", "serviceAccount:...", "domain:corp.com").
# cfg keys, all optional lists: members (exact member strings, for principal://,
# special groups and anything else), emails, domains, service_accounts,
# project_ids, project_numbers. allUsers and allAuthenticatedUsers pass only
# when listed in members.
tocm_member_type(m) := t {
    is_string(m)
    i := indexof(m, ":")
    i > 0
    t := substring(m, 0, i)
}

tocm_member_value(m) := v {
    is_string(m)
    i := indexof(m, ":")
    i > 0
    v := substring(m, i + 1, -1)
}

tocm_member_allowed(m, cfg) {
    trim_space(m) == trim_space(object.get(cfg, "members", [])[_])
}

tocm_member_allowed(m, cfg) {
    {"user", "group"}[tocm_member_type(m)]
    tocm_email_allowed(tocm_member_value(m), object.get(cfg, "emails", []), object.get(cfg, "domains", []))
}

tocm_member_allowed(m, cfg) {
    tocm_member_type(m) == "serviceAccount"
    tocm_sa_allowed(tocm_member_value(m), object.get(cfg, "service_accounts", []), object.get(cfg, "project_ids", []), object.get(cfg, "project_numbers", []))
}

tocm_member_allowed(m, cfg) {
    tocm_member_type(m) == "domain"
    tocm_domain_allowed(tocm_member_value(m), object.get(cfg, "domains", []))
}
# --- toc-match end: email v1 ---

# --- toc-match begin: gcs v1 ---
# Bucket and object of a Cloud Storage URI: gs://BUCKET/OBJECT, or the path
# forms https://storage.googleapis.com/BUCKET/OBJECT and
# https://storage.cloud.google.com/BUCKET/OBJECT. Bare bucket names are
# accepted for allowlist entries. Anything else does not parse.
tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    startswith(lower(u), "gs://")
    rest := substring(u, 5, -1)
}

tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    startswith(lower(u), "https://storage.googleapis.com/")
    rest := substring(u, 31, -1)
}

tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    startswith(lower(u), "https://storage.cloud.google.com/")
    rest := substring(u, 33, -1)
}

tocm_gcs_path(uri) := rest {
    is_string(uri)
    u := trim_space(uri)
    not contains(u, "://")
    not contains(u, "/")
    rest := u
}

tocm_gcs_parts(uri) := {"bucket": b, "object": o} {
    rest := tocm_gcs_path(uri)
    i := indexof(rest, "/")
    i > 0
    b := lower(substring(rest, 0, i))
    o := substring(rest, i + 1, -1)
}

tocm_gcs_parts(uri) := {"bucket": b, "object": ""} {
    rest := tocm_gcs_path(uri)
    not contains(rest, "/")
    rest != ""
    b := lower(rest)
}

# A URI is allowed when its bucket equals an entry's bucket and, if the entry
# names a folder (gs://bucket/folder/), the object sits inside that folder. A
# folder entry without a trailing "/" is read as a folder.
tocm_gcs_allowed(uri, allowed) {
    p := tocm_gcs_parts(uri)
    e := tocm_gcs_parts(allowed[_])
    p.bucket == e.bucket
    e.object == ""
}

tocm_gcs_allowed(uri, allowed) {
    p := tocm_gcs_parts(uri)
    e := tocm_gcs_parts(allowed[_])
    p.bucket == e.bucket
    e.object != ""
    folder := concat("", [trim_suffix(e.object, "/"), "/"])
    startswith(p.object, folder)
}
# --- toc-match end: gcs v1 ---

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

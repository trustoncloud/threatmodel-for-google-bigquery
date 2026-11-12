package wiz

# --- Configuration ---
authorized_data_source_ids := {
    "google_cloud_storage",
    "scheduled_query"
}

# Destination datasets, each with the project that holds it. A transfer
# writes to a dataset in its own project, and the payload names that project
# by its NUMBER.
authorized_destination_datasets := {
    "projects/123456789012/datasets/raw_ingestion_zone",
    "projects/123456789012/datasets/my_governed_dataset"
}

# Allowlist of identities (users or service accounts) authorized to RUN transfers
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

# --- Logic ---
default result := "pass"

# Transfer configs use snake_case fields and carry the full path in name.
is_transfer_config {
    contains(object.get(input, "name", ""), "/transferConfigs/")
}

# name is "projects/<number>/locations/<location>/transferConfigs/<id>".
transfer_project := project {
    parts := split(input.name, "/")
    parts[0] == "projects"
    project := parts[1]
} else := ""

# The destination dataset sits inside the Destination oneof wrapper.
destination_dataset := object.get(object.get(input, "Destination", {}), "DestinationDatasetId", "")

destination_name := sprintf("projects/%s/datasets/%s", [transfer_project, destination_dataset])

# The identity the transfer runs as. The API can leave it out.
owner_email := object.get(object.get(input, "owner_info", {}), "email", "")

# params is a protobuf Struct: params.fields.<key>.Kind.StringValue / BoolValue.
param_string(key) := val {
    val := input.params.fields[key].Kind.StringValue
} else := ""

# A flag is on when it is the boolean true or the string "true".
param_is_true(key) {
    input.params.fields[key].Kind.BoolValue == true
}

param_is_true(key) {
    lower(input.params.fields[key].Kind.StringValue) == "true"
}

# 1. Check Source ID
fail_unauthorized_source_type {
    not authorized_data_source_ids[object.get(input, "data_source_id", "")]
}

# 2. Check Destination: project and dataset together
fail_unauthorized_destination {
    not tocm_gcp_name_allowed(destination_name, authorized_destination_datasets)
}

# 3. Check Run Identity (Privilege Escalation Protection)
# The resource exposes the identity at owner_info.email; the write-only
# serviceAccountName request parameter never appears on the resource. A
# transfer with no owner reported runs as an identity nobody can confirm.
fail_unauthorized_identity {
    not tocm_email_allowed(owner_email, authorized_transfer_identities, [])
}

# 4. GCS-specific: the source path must sit in an approved bucket or folder
fail_bad_gcs_params {
    object.get(input, "data_source_id", "") == "google_cloud_storage"
    not tocm_gcs_allowed(param_string("data_path_template"), authorized_gcs_paths)
}

# 5. GCS-specific: destructive source deletion must be disabled
fail_destructive_action {
    object.get(input, "data_source_id", "") == "google_cloud_storage"
    param_is_true("delete_source_files")
}

# --- Aggregation ---
result := "skip" {
    not is_transfer_config
} else := "fail" {
    fail_unauthorized_source_type
} else := "fail" {
    fail_unauthorized_destination
} else := "fail" {
    fail_unauthorized_identity
} else := "fail" {
    fail_bad_gcs_params
} else := "fail" {
    fail_destructive_action
}

# --- Metadata ---
issues[msg] {
    fail_unauthorized_source_type
    msg := sprintf("data source '%v' is not approved", [object.get(input, "data_source_id", "")])
}

issues[msg] {
    fail_unauthorized_destination
    msg := sprintf("destination '%v' is not approved", [destination_name])
}

issues[msg] {
    fail_unauthorized_identity
    owner_email != ""
    msg := sprintf("run identity '%v' is not approved", [owner_email])
}

issues[msg] {
    fail_unauthorized_identity
    owner_email == ""
    msg := "no run identity is reported, so it cannot be confirmed"
}

issues[msg] {
    fail_bad_gcs_params
    msg := sprintf("source path '%v' is outside the approved buckets and folders", [param_string("data_path_template")])
}

issues[msg] {
    fail_destructive_action
    msg := "the transfer deletes its source files after loading"
}

currentConfiguration := sprintf("Issues found: %v", [concat("; ", sort([m | m := issues[_]]))]) {
    result == "fail"
} else := "Transfer source, destination, run identity and Cloud Storage settings are approved. A scheduled query's SQL was not read."

expectedConfiguration := "Transfers must use an approved data source, an approved destination dataset in an approved project, an approved run identity, and for Cloud Storage an approved bucket or folder with source deletion off. The SQL of a scheduled query is not read, so what it reads, writes or exports is not checked."

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

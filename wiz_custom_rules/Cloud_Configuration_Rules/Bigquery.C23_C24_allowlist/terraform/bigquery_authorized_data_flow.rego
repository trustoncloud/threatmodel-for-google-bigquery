package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Cloud Storage locations data may be read from (external tables and load
# jobs). "gs://bucket" approves the whole bucket; "gs://bucket/folder/"
# approves only what is inside that folder.
authorized_source_gcs := {
    "gs://my-corp-data-lake",
    "gs://partner-upload-bucket/incoming/"
}

# Cloud Storage locations data may be exported to (extract jobs). A location
# approved as a source is not a destination unless it is listed here too.
authorized_destination_gcs := {
    "gs://my-corp-data-lake/exports/"
}

# Hosts of sources outside Cloud Storage that an external table may read,
# such as Google Drive. A host approves every file on it. "*.example.com"
# approves subdomains of example.com.
authorized_source_hosts := {
    "drive.google.com"
}

# BigQuery tables and models a job may read (extract and copy jobs), as
# "projects/<project-id>/datasets/<dataset>/tables/<table>". An entry that
# stops at the dataset, "projects/<project-id>/datasets/<dataset>", approves
# every table and model in that dataset.
authorized_source_tables_by_project_id := {
    "projects/my-project/datasets/analytics_data"
}

# BigQuery tables a job may write (load, copy and query jobs), in the same
# form. A table approved as a source is not a destination unless it is
# listed here too.
authorized_destination_tables_by_project_id := {
    "projects/my-project/datasets/analytics_data/tables/partner_feed"
}

# --- Helpers ---
# A Cloud Storage URI is judged by bucket and folder only, never by host.
source_allowed(uri) {
    tocm_gcs_allowed(uri, authorized_source_gcs)
}

source_allowed(uri) {
    not tocm_gcs_parts(uri)
    tocm_url_host_allowed(uri, authorized_source_hosts)
}

destination_allowed(uri) {
    tocm_gcs_allowed(uri, authorized_destination_gcs)
}

# A URI set from a variable or another resource is not known until apply,
# so it is never approved.
uri_problem(kind, uri) := sprintf("%s URI '%v' is not known until apply", [kind, uri]) {
    tocm_tf_unresolved(uri)
} else := sprintf("%s URI '%v' is not approved", [kind, uri])

source_expected := sprintf("source URIs must be in an approved Cloud Storage bucket or folder %v, or on an approved host %v", [authorized_source_gcs, authorized_source_hosts])

# --- Logic ---
# Finding: external table reading from a source that is not approved.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    cfg := terraLib.getValueArrayOrObject(tbl.external_data_configuration)
    uri := terraLib.getArray(cfg.source_uris)[uidx]
    not source_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].external_data_configuration.source_uris[%d]", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": source_expected,
        "keyActualValue": uri_problem("source", uri),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: load job reading from a source that is not approved.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    load := terraLib.getValueArrayOrObject(job.load)
    uri := terraLib.getArray(load.source_uris)[uidx]
    not source_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].load.source_uris[%d]", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": source_expected,
        "keyActualValue": uri_problem("source", uri),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: extract job writing to a destination that is not approved.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    extract := terraLib.getValueArrayOrObject(job.extract)
    uri := terraLib.getArray(extract.destination_uris)[uidx]
    not destination_allowed(uri)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].extract.destination_uris[%d]", [name, uidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("destination URIs must be in an approved Cloud Storage bucket or folder: %v", [authorized_destination_gcs]),
        "keyActualValue": uri_problem("destination", uri),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: job reading or writing a BigQuery table that is not approved.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    ep := job_endpoints(job)[_]
    problem := endpoint_problem(ep)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].%s", [name, ep.path]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": endpoint_expected[ep.flow],
        "keyActualValue": problem,
        "resourceTags": object.get(job, "labels", {}),
    }
}

# Finding: job whose settings are built in part by a dynamic block, which
# the source does not show, so its tables cannot be read.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    kind := ["load", "extract", "copy", "query"][_]
    block := terraLib.getValueArrayOrObject(job[kind])
    block.dynamic

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].%s.dynamic", [name, kind]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "the tables a job reads and writes must be written in the resource",
        "keyActualValue": sprintf("the %s block builds part of its settings with a dynamic block, so its tables cannot be read", [kind]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

# --- Table endpoints ---
# Every BigQuery table or model a job names: where it sits in the resource,
# which way the data flows and the reference itself.
job_endpoints(job) := load_destination | extract_table | extract_model | copy_sources | copy_destination | query_destination {
    load_destination := {e |
        load := terraLib.getValueArrayOrObject(job.load)
        ref := terraLib.getValueArrayOrObject(load.destination_table)
        e := {"path": "load.destination_table", "flow": "destination", "collection": "tables", "id_key": "table_id", "ref": ref}
    }
    extract_table := {e |
        extract := terraLib.getValueArrayOrObject(job.extract)
        ref := terraLib.getValueArrayOrObject(extract.source_table)
        e := {"path": "extract.source_table", "flow": "source", "collection": "tables", "id_key": "table_id", "ref": ref}
    }
    extract_model := {e |
        extract := terraLib.getValueArrayOrObject(job.extract)
        ref := terraLib.getValueArrayOrObject(extract.source_model)
        e := {"path": "extract.source_model", "flow": "source", "collection": "models", "id_key": "model_id", "ref": ref}
    }
    copy_sources := {e |
        copy := terraLib.getValueArrayOrObject(job.copy)
        ref := terraLib.getArray(copy.source_tables)[idx]
        e := {"path": sprintf("copy.source_tables[%d]", [idx]), "flow": "source", "collection": "tables", "id_key": "table_id", "ref": ref}
    }
    copy_destination := {e |
        copy := terraLib.getValueArrayOrObject(job.copy)
        ref := terraLib.getValueArrayOrObject(copy.destination_table)
        e := {"path": "copy.destination_table", "flow": "destination", "collection": "tables", "id_key": "table_id", "ref": ref}
    }
    query_destination := {e |
        query := terraLib.getValueArrayOrObject(job.query)
        ref := terraLib.getValueArrayOrObject(query.destination_table)
        e := {"path": "query.destination_table", "flow": "destination", "collection": "tables", "id_key": "table_id", "ref": ref}
    }
}

# The full name of an endpoint. The provider takes it as project_id,
# dataset_id and an ID, or as a full path in the ID
# (projects/<project>/datasets/<dataset>/tables/<table>), which then stands
# alone. A part that is left out or is not a literal value leaves the name
# unknown.
endpoint_name(ep) := id {
    id := ep.ref[ep.id_key]
    is_literal(id)
    parts := split(id, "/")
    count(parts) == 6
    parts[0] == "projects"
    parts[2] == "datasets"
    parts[4] == ep.collection
}

endpoint_name(ep) := name {
    id := ep.ref[ep.id_key]
    is_literal(id)
    not contains(id, "/")
    is_literal(ep.ref.project_id)
    is_literal(ep.ref.dataset_id)
    name := sprintf("projects/%s/datasets/%s/%s/%s", [ep.ref.project_id, ep.ref.dataset_id, ep.collection, id])
}

is_literal(value) {
    is_string(value)
    value != ""
    not tocm_tf_unresolved(value)
}

endpoint_lists := {
    "source": authorized_source_tables_by_project_id,
    "destination": authorized_destination_tables_by_project_id,
}

endpoint_expected := {
    "source": sprintf("tables and models a job reads must be listed in authorized_source_tables_by_project_id: %v", [authorized_source_tables_by_project_id]),
    "destination": sprintf("tables a job writes must be listed in authorized_destination_tables_by_project_id: %v", [authorized_destination_tables_by_project_id]),
}

# Approved by its own name, or by an entry that names its dataset.
endpoint_allowed(name, allowed) {
    tocm_gcp_name_allowed(name, allowed)
}

endpoint_allowed(name, allowed) {
    dataset := concat("/", array.slice(split(name, "/"), 0, 4))
    tocm_gcp_name_allowed(dataset, allowed)
}

endpoint_problem(ep) := sprintf("%s '%s' is not approved", [ep.flow, name]) {
    name := endpoint_name(ep)
    not endpoint_allowed(name, endpoint_lists[ep.flow])
}

endpoint_problem(ep) := sprintf("%s cannot be read from the source: write project_id, dataset_id and %s as literal values, or %s as a full path", [ep.flow, ep.id_key, ep.id_key]) {
    not endpoint_name(ep)
}

# --- Matching helpers ---
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

# --- toc-match begin: url v1 ---
# Lowercased host of an http(s) URL, without user info or port.
tocm_url_host(url) := h {
    is_string(url)
    u := lower(trim_space(url))
    i := indexof(u, "://")
    i > 0
    rest := substring(u, i + 3, -1)
    authority := split(rest, "/")[0]
    hostport := tocm_url_last(split(authority, "@"))
    h := trim_suffix(split(hostport, ":")[0], ".")
    h != ""
}

tocm_url_last(arr) := arr[count(arr) - 1]

# Host matches by equality; "*.example.com" admits subdomains across a "."
# boundary, never example.com itself.
tocm_url_host_allowed(url, allowed) {
    h := tocm_url_host(url)
    entry := lower(trim_space(allowed[_]))
    not startswith(entry, "*.")
    h == entry
}

tocm_url_host_allowed(url, allowed) {
    h := tocm_url_host(url)
    entry := lower(trim_space(allowed[_]))
    startswith(entry, "*.")
    suffix := substring(entry, 1, -1)
    count(h) > count(suffix)
    endswith(h, suffix)
}
# --- toc-match end: url v1 ---

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

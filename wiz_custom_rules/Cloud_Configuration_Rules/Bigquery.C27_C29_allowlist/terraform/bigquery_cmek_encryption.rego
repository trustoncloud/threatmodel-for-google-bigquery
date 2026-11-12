package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher.
# Approved Cloud KMS keys, by full name: project, location, key ring and key
# must all match. List each key without a version. BigQuery names a key,
# never a key version, so an entry ending in /cryptoKeyVersions/<n> matches
# nothing.
authorized_kms_keys := {
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key",
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key"
}

# --- Helpers ---
key_authorized(key) {
    tocm_kms_allowed(key, authorized_kms_keys)
}

dataset_key(ds) := key {
    cfg := terraLib.getValueArrayOrObject(ds.default_encryption_configuration)
    key := cfg.kms_key_name
    key != ""
}

table_key(tbl) := key {
    cfg := terraLib.getValueArrayOrObject(tbl.encryption_configuration)
    key := cfg.kms_key_name
    key != ""
}

# An external dataset holds no data of its own: the data stays in the
# external source, so the dataset has no default key to set and is out of
# scope.
is_external_dataset(ds) {
    ds.external_dataset_reference
}

# A table belongs to a dataset in the scan when the two share a module, its
# dataset_id is that dataset's ID or a reference to that dataset resource,
# and both name the same project (or both leave the project to the same
# provider configuration).
table_in_dataset(tbl, tbl_doc, ds, ds_doc, dsname) {
    same_module(tbl, tbl_doc, ds_doc, dsname)
    same_dataset_id(tbl, ds, dsname)
    same_project(tbl, ds, dsname)
}

# Nothing shows the two share a module, so both must write the same dataset
# ID and the same project.
table_in_dataset(tbl, tbl_doc, ds, ds_doc, dsname) {
    is_literal(tbl.dataset_id)
    tbl.dataset_id == ds.dataset_id
    is_literal(tbl.project)
    tbl.project == ds.project
}

# Two resources are known to share a module, and with it a default project,
# when they sit in the same file, or when one points at the dataset by a
# resource name that only one dataset in the scan has. A scan can hold files
# from several modules, so the same ID in another file proves nothing.
same_module(res, res_doc, ds_doc, dsname) {
    res_doc == ds_doc
}

same_module(res, res_doc, ds_doc, dsname) {
    res.dataset_id == sprintf("${google_bigquery_dataset.%s.dataset_id}", [dsname])
    count({d | input.document[d].resource.google_bigquery_dataset[dsname]}) == 1
}

# A value written in the resource. A value taken from a variable or another
# resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

same_dataset_id(tbl, ds, dsname) {
    tbl.dataset_id == sprintf("${google_bigquery_dataset.%s.dataset_id}", [dsname])
}

same_dataset_id(tbl, ds, dsname) {
    tbl.dataset_id == ds.dataset_id
}

# Neither sets a project, so each takes the default project of its provider
# configuration. That is the same project only when both use the same
# provider configuration.
same_project(tbl, ds, dsname) {
    object.get(tbl, "project", "") == ""
    object.get(ds, "project", "") == ""
    provider_configuration(tbl) == provider_configuration(ds)
}

# The provider configuration a resource uses. Leaving provider out and
# writing provider = google both select the default configuration.
provider_configuration(resource) := "google" {
    default_provider_values[object.get(resource, "provider", "")]
} else := object.get(resource, "provider", "")

default_provider_values := {"", "google", "${google}"}

same_project(tbl, ds, dsname) {
    tbl.project == ds.project
}

same_project(tbl, ds, dsname) {
    tbl.project == sprintf("${google_bigquery_dataset.%s.project}", [dsname])
}

# A table without its own key takes the default key of its dataset.
inherited_keys(tbl, tbl_doc) := {key |
    ds := input.document[ds_doc].resource.google_bigquery_dataset[dsname]
    table_in_dataset(tbl, tbl_doc, ds, ds_doc, dsname)
    key := dataset_key(ds)
}

# A key set from a variable or another resource is not known until apply,
# so it is never approved.
key_problem(key) := sprintf("kms_key_name is '%v', which is not known until apply", [key]) {
    tocm_tf_unresolved(key)
} else := sprintf("kms_key_name is '%v', which is not an approved key", [key])

# --- Logic ---
# Finding: dataset without CMEK.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not is_external_dataset(ds)
    not dataset_key(ds)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_encryption_configuration.kms_key_name", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "default_encryption_configuration.kms_key_name must be set to an approved CMEK",
        "keyActualValue": "dataset uses Google-managed encryption (no CMEK)",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: dataset CMEK not in the approved set.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not is_external_dataset(ds)
    key := dataset_key(ds)
    not key_authorized(key)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].default_encryption_configuration.kms_key_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("kms_key_name must be one of the approved keys (same project, location, key ring and key): %v", [authorized_kms_keys]),
        "keyActualValue": key_problem(key),
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: table without its own key and without a dataset default key to
# inherit in this scan.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    not table_key(tbl)
    count(inherited_keys(tbl, i)) == 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].encryption_configuration.kms_key_name", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "encryption_configuration.kms_key_name must be set to an approved CMEK, or the table's dataset in this scan must have an approved default key",
        "keyActualValue": "table has no key of its own and no dataset default key in this scan (Google-managed encryption)",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: table without its own key, inheriting a dataset default key that
# is not in the approved set.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    not table_key(tbl)
    key := inherited_keys(tbl, i)[_]
    not key_authorized(key)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].dataset_id", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("a table without its own key must inherit one of the approved keys: %v", [authorized_kms_keys]),
        "keyActualValue": sprintf("table inherits its dataset's default key: %v", [key_problem(key)]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: table CMEK not in the approved set.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    key := table_key(tbl)
    not key_authorized(key)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].encryption_configuration.kms_key_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("kms_key_name must be one of the approved keys (same project, location, key ring and key): %v", [authorized_kms_keys]),
        "keyActualValue": key_problem(key),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# --- Matching helpers ---
# --- toc-match begin: kms v1 ---
# Parts of a Cloud KMS key name, with or without "//cloudkms.googleapis.com/"
# and with or without "/cryptoKeyVersions/V".
tocm_kms_parts(name) := {"project": s[1], "location": lower(s[3]), "key_ring": s[5], "key": s[7], "version": ""} {
    s := split(tocm_kms_rel(name), "/")
    count(s) == 8
    tocm_kms_shape(s)
}

tocm_kms_parts(name) := {"project": s[1], "location": lower(s[3]), "key_ring": s[5], "key": s[7], "version": s[9]} {
    s := split(tocm_kms_rel(name), "/")
    count(s) == 10
    tocm_kms_shape(s)
    s[8] == "cryptoKeyVersions"
    s[9] != ""
}

tocm_kms_rel(name) := r {
    is_string(name)
    r := trim_prefix(trim_space(name), "//cloudkms.googleapis.com/")
}

tocm_kms_shape(s) {
    s[0] == "projects"
    s[2] == "locations"
    s[4] == "keyRings"
    s[6] == "cryptoKeys"
    s[1] != ""
    s[3] != ""
    s[5] != ""
    s[7] != ""
}

# A key is allowed when project, location, key ring and key all equal an
# entry's. An entry with a version admits that version only; an entry
# without one admits the key at any version.
tocm_kms_allowed(name, allowed) {
    k := tocm_kms_parts(name)
    e := tocm_kms_parts(allowed[_])
    k.project == e.project
    k.location == e.location
    k.key_ring == e.key_ring
    k.key == e.key
    e.version == ""
}

tocm_kms_allowed(name, allowed) {
    k := tocm_kms_parts(name)
    e := tocm_kms_parts(allowed[_])
    k.project == e.project
    k.location == e.location
    k.key_ring == e.key_ring
    k.key == e.key
    e.version != ""
    k.version == e.version
}
# --- toc-match end: kms v1 ---

# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

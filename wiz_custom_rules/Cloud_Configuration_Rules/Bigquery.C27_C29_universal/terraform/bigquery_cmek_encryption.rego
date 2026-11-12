package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal baseline: every dataset has a default CMEK, and every table has
# its own key or inherits its dataset's default key.

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
        "keyExpectedValue": "default_encryption_configuration.kms_key_name must be set (CMEK required)",
        "keyActualValue": "dataset uses Google-managed encryption (no CMEK)",
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
        "keyExpectedValue": "encryption_configuration.kms_key_name must be set, or the table's dataset in this scan must have a default key (CMEK required)",
        "keyActualValue": "table has no key of its own and no dataset default key in this scan (Google-managed encryption)",
        "resourceTags": object.get(tbl, "labels", {}),
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

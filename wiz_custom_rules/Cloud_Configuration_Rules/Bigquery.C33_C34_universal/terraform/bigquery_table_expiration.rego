package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal data retention baseline: every table must have an expiration.
# A table gets one from its own expiration_time (epoch milliseconds), or from
# the default_table_expiration_ms of its dataset when the two are tied in the
# same scan. Absence of both means infinite retention.
has_own_expiration(tbl) {
    to_number(object.get(tbl, "expiration_time", 0)) != 0
}

# A default written as a number in the dataset. A default taken from a
# variable or another resource is not known until apply, so it gives the
# table nothing to inherit.
dataset_default_ms(ds) := ms {
    ms := to_number(ds.default_table_expiration_ms)
    ms > 0
}

# Datasets in the scan that the table belongs to.
table_datasets(tbl, tbl_doc) := {[ds_doc, dsname] |
    ds := input.document[ds_doc].resource.google_bigquery_dataset[dsname]
    table_in_dataset(tbl, tbl_doc, ds, ds_doc, dsname)
}

# The table inherits an expiration when it is tied to a dataset in the scan
# and every dataset it is tied to sets a default.
inherits_expiration(tbl, tbl_doc) {
    tied := table_datasets(tbl, tbl_doc)
    count(tied) > 0
    without_default := {t |
        t := tied[_]
        not dataset_default_ms(input.document[t[0]].resource.google_bigquery_dataset[t[1]])
    }
    count(without_default) == 0
}

missing_description(tbl, tbl_doc) := "expiration_time is not set, and the dataset the table belongs to sets no default_table_expiration_ms as a number" {
    count(table_datasets(tbl, tbl_doc)) > 0
} else := "expiration_time is not set, and no dataset in this scan gives the table a default expiration"

WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    not has_own_expiration(tbl)
    not inherits_expiration(tbl, i)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].expiration_time", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "expiration_time must be set, or the dataset the table belongs to in this scan must set default_table_expiration_ms (no infinite retention)",
        "keyActualValue": missing_description(tbl, i),
        "resourceTags": object.get(tbl, "labels", {}),
    }
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


# --- Matching helpers ---
# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

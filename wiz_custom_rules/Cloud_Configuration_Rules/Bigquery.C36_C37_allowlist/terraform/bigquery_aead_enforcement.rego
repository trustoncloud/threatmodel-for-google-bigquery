package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Column-level AEAD encryption; function reference:
# https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions
#
# 1. Sensitive columns that must be declared BYTES, the type that holds AEAD
#    ciphertext. The type does not show that a value is encrypted.
#    Keys are "dataset.table": the dataset_id and table_id declared on the
#    google_bigquery_table resource, matched exactly.
#    "project.dataset.table" limits an entry to tables in that project.
#    A bare "table" applies to that table ID in every dataset.
sensitive_columns := {
    "hr_data.employees": {"ssn", "salary"},
    "finance.credit_cards": {"card_number"}
}

# 2. Tables that must be handled with AEAD functions when a declared query
#    names them, as "dataset.table" or "project.dataset.table". Each name in
#    the SQL text is compared part by part, ignoring case and backticks, so a
#    table with a longer name is a different table.
sensitive_table_refs := {
    "hr_data.employees",
    "finance.credit_cards"
}

# --- Helpers ---
# The query text is not parsed: a function name anywhere in it counts, so
# this does not show that the sensitive column is the value encrypted.
uses_aead(sql) {
    contains(upper(sql), "AEAD.ENCRYPT")
}

uses_aead(sql) {
    contains(upper(sql), "DETERMINISTIC_ENCRYPT")
}

# The names in a query, read without parsing the SQL: backticks are dropped
# and every run of name characters is one name, split at its dots.
query_names(sql) := {parts |
    is_string(sql)
    name := regex.find_n(`[A-Za-z0-9_][A-Za-z0-9_.-]*`, replace(sql, "`", ""), -1)[_]
    parts := split(lower(trim_suffix(name, ".")), ".")
}

# A query names a table when the table's parts sit side by side in one of
# its names: alone, after a project, or before a column.
query_names_table(sql, ref) {
    want := split(lower(ref), ".")
    parts := query_names(sql)[_]
    some start
    parts[start]
    array.slice(parts, start, start + count(want)) == want
}

# One entry of sensitive_columns, split into its parts. "" means any.
sensitive_entries[e] {
    cols := sensitive_columns[key]
    parts := split(key, ".")
    count(parts) == 3
    e := {"key": key, "project": parts[0], "dataset": parts[1], "table": parts[2], "columns": cols}
}

sensitive_entries[e] {
    cols := sensitive_columns[key]
    parts := split(key, ".")
    count(parts) == 2
    e := {"key": key, "project": "", "dataset": parts[0], "table": parts[1], "columns": cols}
}

sensitive_entries[e] {
    cols := sensitive_columns[key]
    parts := split(key, ".")
    count(parts) == 1
    e := {"key": key, "project": "", "dataset": "", "table": parts[0], "columns": cols}
}

# The dataset a table sits in: its own dataset_id, or the dataset_id of the
# google_bigquery_dataset resource it points at. Empty when the source does
# not state it.
table_dataset_ids(tbl, doc) := ids {
    literal := {d |
        d := tbl.dataset_id
        is_string(d)
        not tocm_tf_unresolved(d)
    }
    referenced := {d |
        found := regex.find_all_string_submatch_n(`^\$\{\s*google_bigquery_dataset\.([A-Za-z0-9_-]+)\.dataset_id\s*\}$`, sprintf("%v", [tbl.dataset_id]), 1)
        count(found) == 1
        d := referenced_dataset(doc, found[0][1]).dataset_id
        is_string(d)
        not tocm_tf_unresolved(d)
    }
    ids := literal | referenced
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

project_is_known(tbl) {
    is_string(tbl.project)
    tbl.project != ""
    not tocm_tf_unresolved(tbl.project)
}

# An entry applies when the table ID, dataset and project all equal the
# entry's. A dataset or project the source does not state (a variable with no
# default, or the provider default) is treated as the listed one.
entry_applies(e, tbl, doc) {
    tbl.table_id == e.table
    dataset_applies(e, tbl, doc)
    project_applies(e, tbl)
}

dataset_applies(e, tbl, doc) {
    e.dataset == ""
}

dataset_applies(e, tbl, doc) {
    table_dataset_ids(tbl, doc)[e.dataset]
}

dataset_applies(e, tbl, doc) {
    count(table_dataset_ids(tbl, doc)) == 0
}

project_applies(e, tbl) {
    e.project == ""
}

project_applies(e, tbl) {
    tbl.project == e.project
}

project_applies(e, tbl) {
    not project_is_known(tbl)
}

# BigQuery column names ignore case.
column_listed(e, column_name) {
    lower(e.columns[_]) == lower(column_name)
}

# A schema is readable when it is written as JSON text in the resource. One
# loaded with file() or built with jsonencode() is not in the source as text.
schema_readable(tbl) {
    is_string(tbl.schema)
    not tocm_tf_unresolved(tbl.schema)
    json.is_valid(tbl.schema)
}

# --- Logic ---
# Finding: designated sensitive column declared with a type other than BYTES.
# The table schema is a JSON string of field objects; nested RECORD fields
# are covered by walking the parsed document.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    e := sensitive_entries[_]
    entry_applies(e, tbl, i)
    schema_readable(tbl)
    parsed := json.unmarshal(tbl.schema)
    [_, field] := walk(parsed)
    column_listed(e, field.name)
    upper(field.type) != "BYTES"

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].schema", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("sensitive column '%v' of '%v' must be declared BYTES, the type that holds AEAD ciphertext (the type alone does not show the value is encrypted)", [field.name, e.key]),
        "keyActualValue": sprintf("column '%v' is declared with type '%v', which cannot hold AEAD ciphertext", [field.name, field.type]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: sensitive table whose schema the source does not show as text, so
# its column types cannot be read.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    tbl.schema
    not schema_readable(tbl)
    keys := {e.key | e := sensitive_entries[_]; entry_applies(e, tbl, i)}
    count(keys) > 0

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].schema", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("the schema of sensitive table %v must be written as JSON text in the resource, so the type of each sensitive column can be read", [sort(keys)]),
        "keyActualValue": "schema is loaded with file() or built with an expression, so its column types cannot be read",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: declared query names a sensitive table and calls no AEAD function.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    sql := q.query
    ref := sensitive_table_refs[_]
    query_names_table(sql, ref)
    not uses_aead(sql)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.query", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("queries that name a sensitive table must call AEAD.ENCRYPT or DETERMINISTIC_ENCRYPT: %v (the query text is not parsed, so a call anywhere in it is accepted)", [sensitive_table_refs]),
        "keyActualValue": sprintf("query names '%v' and calls no AEAD encryption function", [ref]),
        "resourceTags": object.get(job, "labels", {}),
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

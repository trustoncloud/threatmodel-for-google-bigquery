package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Column-level AEAD encryption; function reference:
# https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/aead_encryption_functions
#
# 1. Sensitive columns that must be stored as AEAD ciphertext (type BYTES),
#    keyed by the table_id declared on the google_bigquery_table resource.
sensitive_columns := {
    "employees": {"ssn", "salary"},
    "credit_cards": {"card_number"}
}

# 2. Table references that must be handled with AEAD functions when they
#    appear in a declared query, matched as substrings of the SQL text.
sensitive_table_refs := {
    "hr_data.employees",
    "finance.credit_cards"
}

# --- Helpers ---
# Any function of the documented AEAD family counts as column-level encryption.
uses_aead(sql) {
    contains(upper(sql), "AEAD.ENCRYPT")
}

uses_aead(sql) {
    contains(upper(sql), "DETERMINISTIC_ENCRYPT")
}

# --- Logic ---
# Finding: designated sensitive column declared with a plaintext type.
# The table schema is a JSON string of field objects; nested RECORD fields
# are covered by walking the parsed document.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    cols := sensitive_columns[tbl.table_id]
    parsed := json.unmarshal(tbl.schema)
    [_, field] := walk(parsed)
    cols[field.name]
    upper(field.type) != "BYTES"

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].schema", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("sensitive column '%v' must be stored as AEAD ciphertext (type BYTES)", [field.name]),
        "keyActualValue": sprintf("column '%v' is declared with plaintext type '%v'", [field.name, field.type]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: declared query touches a sensitive table without AEAD functions.
WizPolicy[result] {
    document := input.document[i]
    job := document.resource.google_bigquery_job[name]
    q := terraLib.getValueArrayOrObject(job.query)
    sql := q.query
    ref := sensitive_table_refs[_]
    contains(sql, ref)
    not uses_aead(sql)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_job",
        "resourceName": terraLib.get_resource_name(job, name),
        "searchKey": sprintf("google_bigquery_job[%s].query.query", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("queries referencing sensitive tables must use AEAD functions: %v", [sensitive_table_refs]),
        "keyActualValue": sprintf("query references '%v' without AEAD encryption", [ref]),
        "resourceTags": object.get(job, "labels", {}),
    }
}

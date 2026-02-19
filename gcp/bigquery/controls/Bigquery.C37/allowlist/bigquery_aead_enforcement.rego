package wiz

# --- Configuration ---
# List the fully qualified Table IDs that MUST be AEAD encrypted.
sensitive_tables := {
    "my-project:hr_data.employees",
    "my-project:finance.credit_cards"
}

# --- Logic ---
default result := "pass"

is_job { input.type == "google_bigquery_job" }

# 1. Identify if the Job interacts with a Sensitive Table
# Classic iteration: We assign the array to a variable, then iterate using [_]
targets_sensitive_table {
    is_job
    
    # Safely retrieve the list of tables (default to empty list)
    referenced_list := object.get(input.properties.statistics.query, "referencedTables", [])
    
    # ITERATION: 'referenced_table' becomes each item in the list
    referenced_table := referenced_list[_]
    
    # Construct the ID to match our config format
    table_id := sprintf("%v:%v.%v", [referenced_table.projectId, referenced_table.datasetId, referenced_table.tableId])
    
    # Check if this table is in our sensitive list
    sensitive_tables[table_id]
}

# 2. Check for AEAD usage in the Query Text
uses_aead {
    # Safely get query text
    query_text := object.get(input.properties.configuration.query, "query", "")
    
    # Check for the AEAD.ENCRYPT function (case-insensitive check using upper())
    contains(upper(query_text), "AEAD.ENCRYPT")
}

# --- Failure Condition ---
# Fail if the job touches a sensitive table BUT does not use encryption
fail_plaintext_write {
    targets_sensitive_table
    not uses_aead
}

# --- Aggregation ---
result := "skip" {
    not is_job
} else := "skip" {
    # Skip jobs that don't touch our sensitive tables
    is_job
    not targets_sensitive_table
} else := "fail" {
    fail_plaintext_write
}

# --- Metadata ---
currentConfiguration := "Job accesses sensitive table without AEAD encryption" {
    fail_plaintext_write
} else := "Job uses AEAD encryption or targets non-sensitive data"

expectedConfiguration := "Jobs interacting with sensitive tables must use AEAD.ENCRYPT functions."
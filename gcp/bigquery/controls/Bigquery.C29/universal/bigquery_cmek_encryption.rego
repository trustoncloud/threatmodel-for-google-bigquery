package wiz

default result := "pass"

# 1. Resource Identification
is_dataset { input.type == "google_bigquery_dataset" }
is_table   { input.type == "google_bigquery_table" }

# 2. Check for CMEK Presence
# Dataset: Must have defaultEncryptionConfiguration.kmsKeyName
has_cmek {
    is_dataset
    input.properties.defaultEncryptionConfiguration.kmsKeyName != ""
}

# Table: Must have encryptionConfiguration.kmsKeyName
has_cmek {
    is_table
    input.properties.encryptionConfiguration.kmsKeyName != ""
}

# 3. Aggregation
result := "skip" {
    not is_dataset
    not is_table
} else := "fail" {
    not has_cmek
}

# --- Metadata ---
currentConfiguration := "Resource is using Google-Managed Encryption (No CMEK)" {
    result == "fail"
} else := "Resource is encrypted with CMEK"

expectedConfiguration := "BigQuery resources must be encrypted with a Customer-Managed Encryption Key (CMEK)."
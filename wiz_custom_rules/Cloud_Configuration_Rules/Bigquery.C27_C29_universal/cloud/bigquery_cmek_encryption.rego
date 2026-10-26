package wiz

default result := "pass"

# Routed types: datasets carry defaultEncryptionConfiguration; tables and
# models carry encryptionConfiguration. The config block is absent when the
# resource uses Google-managed encryption.
is_supported_resource {
    input.datasetReference
}
is_supported_resource {
    input.tableReference
}
is_supported_resource {
    input.modelReference
}

# 1. Check for CMEK Presence
has_cmek {
    input.defaultEncryptionConfiguration.kmsKeyName != ""
}

has_cmek {
    input.encryptionConfiguration.kmsKeyName != ""
}

# 2. Aggregation
result := "skip" {
    not is_supported_resource
} else := "fail" {
    not has_cmek
}

# --- Metadata ---
currentConfiguration := "Resource is using Google-Managed Encryption (No CMEK)" {
    result == "fail"
} else := "Resource is encrypted with CMEK"

expectedConfiguration := "BigQuery resources must be encrypted with a Customer-Managed Encryption Key (CMEK)."

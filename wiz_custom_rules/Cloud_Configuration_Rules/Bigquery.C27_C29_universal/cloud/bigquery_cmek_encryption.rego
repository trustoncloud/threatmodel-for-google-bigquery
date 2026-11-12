package wiz

default result := "pass"

# The encryption block is absent when the dataset uses Google-managed
# encryption.
has_cmek {
    input.defaultEncryptionConfiguration.kmsKeyName != ""
}

# A linked dataset is a read-only view of data another project shares, and
# names the dataset it is linked from in linkedDatasetSource. Its data is
# encrypted where it is stored, so it has no default key to set and is
# skipped.
is_linked_dataset {
    input.linkedDatasetSource
}

# --- Aggregation ---
result := "skip" {
    not input.datasetReference
} else := "skip" {
    is_linked_dataset
} else := "fail" {
    not has_cmek
}

# --- Metadata ---
currentConfiguration := "Linked dataset: read-only, with no default key to set" {
    is_linked_dataset
} else := "Dataset has no default CMEK, so new tables use Google-managed encryption" {
    result == "fail"
} else := "Dataset has a default CMEK"

expectedConfiguration := "The dataset must have a default Customer-Managed Encryption Key (CMEK). Only the dataset default is checked: a table or model created before the default was set keeps its own key."

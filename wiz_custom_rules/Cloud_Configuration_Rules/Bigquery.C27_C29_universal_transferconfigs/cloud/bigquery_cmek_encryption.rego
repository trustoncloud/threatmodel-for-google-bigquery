package wiz

# --- Configuration ---
# Transfer data sources that take a customer-managed key on the transfer
# configuration. A transfer from any other source is skipped. Add a source
# only when its BigQuery Data Transfer Service page documents a
# customer-managed key for it.
cmek_capable_transfer_sources := {
    "amazon_s3",
    "azure_blob_storage",
    "ga4",
    "google_cloud_storage",
    "scheduled_query",
    "snowflake_migration"
}

# --- Logic ---
default result := "pass"

is_dataset {
    input.datasetReference
}

# A transfer configuration is named
# "projects/<number>/locations/<location>/transferConfigs/<id>".
is_transfer_config {
    not is_dataset
    contains(object.get(input, "name", ""), "/transferConfigs/")
}

transfer_source := s {
    s := input.data_source_id
    is_string(s)
} else := ""

is_cmek_capable_transfer {
    is_transfer_config
    cmek_capable_transfer_sources[transfer_source]
}

# A transfer configuration reports the key in effect, as a string wrapper.
# The encryption block is absent when the transfer has no key.
transfer_key_name := val {
    val := input.encryption_configuration.kms_key_name.value
    is_string(val)
    val != ""
} else := val {
    val := input.encryption_configuration.kms_key_name
    is_string(val)
    val != ""
} else := val {
    val := input.encryptionConfiguration.kmsKeyName
    is_string(val)
    val != ""
}

# The encryption block is absent when the dataset uses Google-managed
# encryption.
has_cmek {
    input.defaultEncryptionConfiguration.kmsKeyName != ""
}

has_cmek {
    is_transfer_config
    transfer_key_name
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
    not is_dataset
    not is_transfer_config
} else := "skip" {
    is_linked_dataset
} else := "skip" {
    is_transfer_config
    not is_cmek_capable_transfer
} else := "fail" {
    not has_cmek
}

# --- Metadata ---
currentConfiguration := "Linked dataset: read-only, with no default key to set" {
    is_linked_dataset
} else := sprintf("Transfer configuration from source '%v', which takes no customer-managed key", [transfer_source]) {
    is_transfer_config
    not is_cmek_capable_transfer
} else := "Transfer configuration has no CMEK, so its data uses Google-managed encryption" {
    is_transfer_config
    result == "fail"
} else := "Transfer configuration has a CMEK" {
    is_transfer_config
} else := "Dataset has no default CMEK, so new tables use Google-managed encryption" {
    result == "fail"
} else := "Dataset has a default CMEK"

expectedConfiguration := "A transfer configuration from a source that takes a customer-managed key must name a Customer-Managed Encryption Key (CMEK). This key covers the data the transfer stages and loads; the destination dataset's default key is checked on the dataset." {
    is_transfer_config
} else := "The dataset must have a default Customer-Managed Encryption Key (CMEK). Only the dataset default is checked: a table or model created before the default was set keeps its own key."

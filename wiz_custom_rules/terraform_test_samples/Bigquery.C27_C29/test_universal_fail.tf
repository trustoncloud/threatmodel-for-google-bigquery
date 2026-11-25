# Bigquery.C29 (bigquery_cmek_encryption) - universal - VIOLATING

# Dataset without CMEK: 1 finding
resource "google_bigquery_dataset" "plain" {
  dataset_id = "plain_data"
  location   = "US"
}

# Table without CMEK in a dataset without a default key: 1 finding
resource "google_bigquery_table" "plain_table" {
  dataset_id = google_bigquery_dataset.plain.dataset_id
  table_id   = "plain_table"
}

# Dataset with a default key, in one project
resource "google_bigquery_dataset" "encrypted" {
  project    = "analytics-prod"
  dataset_id = "encrypted_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/p/locations/us/keyRings/r/cryptoKeys/k"
  }
}

# Same dataset ID in another project, so no key is inherited: 1 finding
resource "google_bigquery_table" "other_project_table" {
  project    = "analytics-dev"
  dataset_id = "encrypted_data"
  table_id   = "other_project_table"
}

# The dataset is not declared in this plan: 1 finding
resource "google_bigquery_table" "orphan_table" {
  dataset_id = "not_in_this_plan"
  table_id   = "orphan_table"
}

# The table uses another provider configuration than the dataset with the
# same ID, so it can sit in another project and inherits no key: 1 finding
provider "google" {
  alias   = "other"
  project = "other-project"
}

resource "google_bigquery_dataset" "default_provider_data" {
  dataset_id = "shared_name_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "other_provider_table" {
  provider   = google.other
  dataset_id = "shared_name_data"
  table_id   = "other_provider_table"
}

# Scheduled query without a key: 1 finding
resource "google_bigquery_data_transfer_config" "scheduled_query_no_key" {
  display_name           = "scheduled_query_no_key"
  location               = "US"
  data_source_id         = "scheduled_query"
  destination_dataset_id = "secured_data"
  schedule               = "every 24 hours"

  params = {
    data_path_template              = "gs://example-landing-bucket/inbound/*.csv"
    destination_table_name_template = "landing"
    file_format                     = "CSV"
  }
}

# Source taken from a variable with no default, so the transfer may take a
# key, and none is set: 1 finding
variable "transfer_source" {
  type = string
}

resource "google_bigquery_data_transfer_config" "source_from_variable" {
  display_name           = "source_from_variable"
  location               = "US"
  data_source_id         = var.transfer_source
  destination_dataset_id = "secured_data"
  schedule               = "every 24 hours"

  params = {
    data_path_template              = "gs://example-landing-bucket/inbound/*.csv"
    destination_table_name_template = "landing"
    file_format                     = "CSV"
  }
}

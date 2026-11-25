# Bigquery.C29 (bigquery_cmek_encryption) - allowlist - VIOLATING

# Dataset with an unauthorized key: 1 finding
resource "google_bigquery_dataset" "rogue_key" {
  dataset_id = "rogue_key_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/rogue-project/locations/us/keyRings/x/cryptoKeys/rogue-key"
  }
}

# Table without its own key, inheriting the unauthorized dataset key: 1 finding
resource "google_bigquery_table" "plain_table" {
  dataset_id = google_bigquery_dataset.rogue_key.dataset_id
  table_id   = "plain_table"
}

# Lookalikes of the approved key: 4 findings
resource "google_bigquery_dataset" "lookalike_key_name" {
  dataset_id = "lookalike_key_name_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key-rogue"
  }
}

resource "google_bigquery_dataset" "lookalike_key_ring" {
  dataset_id = "lookalike_key_ring_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/other-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "lookalike_project" {
  dataset_id = "elsewhere_data"
  table_id   = "lookalike_project"

  encryption_configuration {
    kms_key_name = "projects/my-secure-project-2/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "lookalike_location" {
  dataset_id = "elsewhere_data"
  table_id   = "lookalike_location"

  encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/europe-west1/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

# A key set from a variable with no default is not known until apply: 1 finding
variable "table_kms_key" {
  type = string
}

resource "google_bigquery_table" "unresolved_key" {
  dataset_id = "elsewhere_data"
  table_id   = "unresolved_key"

  encryption_configuration {
    kms_key_name = var.table_kms_key
  }
}

# Dataset with an approved default key, and tables that do not inherit it
resource "google_bigquery_dataset" "secured" {
  project    = "analytics-prod"
  dataset_id = "secured_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_dataset" "secured_archive" {
  project    = "analytics-prod"
  dataset_id = "secured_data_archive"
  location   = "US"
}

# The table sits in secured_archive, which has no default key: 2 findings
# (the dataset and the table)
resource "google_bigquery_table" "archive_table" {
  project    = "analytics-prod"
  dataset_id = google_bigquery_dataset.secured_archive.dataset_id
  table_id   = "archive_table"
}

# Same dataset ID as secured, in another project: 1 finding
resource "google_bigquery_table" "other_project_table" {
  project    = "analytics-dev"
  dataset_id = "secured_data"
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

# Cloud Storage transfer without a key: 1 finding
resource "google_bigquery_data_transfer_config" "gcs_load_no_key" {
  display_name           = "gcs_load_no_key"
  location               = "US"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "secured_data"
  schedule               = "every 24 hours"

  params = {
    data_path_template              = "gs://example-landing-bucket/inbound/*.csv"
    destination_table_name_template = "landing"
    file_format                     = "CSV"
  }
}

# Scheduled query with an unauthorized key: 1 finding
resource "google_bigquery_data_transfer_config" "scheduled_query_rogue_key" {
  display_name           = "scheduled_query_rogue_key"
  location               = "US"
  data_source_id         = "scheduled_query"
  destination_dataset_id = "secured_data"
  schedule               = "every 24 hours"

  params = {
    data_path_template              = "gs://example-landing-bucket/inbound/*.csv"
    destination_table_name_template = "landing"
    file_format                     = "CSV"
  }

  encryption_configuration {
    kms_key_name = "projects/rogue-project/locations/us/keyRings/x/cryptoKeys/rogue-key"
  }
}

# Amazon S3 transfer with a lookalike of the approved key: 1 finding
resource "google_bigquery_data_transfer_config" "s3_lookalike_key" {
  display_name           = "s3_lookalike_key"
  location               = "US"
  data_source_id         = "amazon_s3"
  destination_dataset_id = "secured_data"
  schedule               = "every 24 hours"

  params = {
    data_path_template              = "gs://example-landing-bucket/inbound/*.csv"
    destination_table_name_template = "landing"
    file_format                     = "CSV"
  }

  encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key-rogue"
  }
}

# Key taken from a variable with no default, not known until apply: 1 finding
variable "transfer_kms_key" {
  type = string
}

resource "google_bigquery_data_transfer_config" "gcs_load_key_from_variable" {
  display_name           = "gcs_load_key_from_variable"
  location               = "US"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "secured_data"
  schedule               = "every 24 hours"

  params = {
    data_path_template              = "gs://example-landing-bucket/inbound/*.csv"
    destination_table_name_template = "landing"
    file_format                     = "CSV"
  }

  encryption_configuration {
    kms_key_name = var.transfer_kms_key
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

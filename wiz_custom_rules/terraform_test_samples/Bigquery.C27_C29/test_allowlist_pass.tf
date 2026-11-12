# Bigquery.C29 (bigquery_cmek_encryption) - allowlist - COMPLIANT

resource "google_bigquery_dataset" "secured" {
  dataset_id = "secured_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

# Table with its own approved key
resource "google_bigquery_table" "secured_table" {
  dataset_id = google_bigquery_dataset.secured.dataset_id
  table_id   = "secured_table"

  encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key"
  }
}

# Table without its own key: it inherits the dataset's approved default key
resource "google_bigquery_table" "inherits_by_reference" {
  dataset_id = google_bigquery_dataset.secured.dataset_id
  table_id   = "inherits_by_reference"
}

# The same, with the dataset named by ID and project
resource "google_bigquery_dataset" "secured_prod" {
  project    = "analytics-prod"
  dataset_id = "secured_prod_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/US/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "inherits_by_id" {
  project    = "analytics-prod"
  dataset_id = "secured_prod_data"
  table_id   = "inherits_by_id"
}

# Dataset and table under the same provider configuration: the table
# inherits the dataset's default key
provider "google" {
  alias   = "other"
  project = "other-project"
}

resource "google_bigquery_dataset" "other_provider_data" {
  provider   = google.other
  dataset_id = "other_provider_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "other_provider_table" {
  provider   = google.other
  dataset_id = "other_provider_data"
  table_id   = "other_provider_table"
}

# The dataset leaves provider out and the table names the default provider:
# both use the same configuration, so the table inherits the key
resource "google_bigquery_dataset" "implicit_provider_data" {
  dataset_id = "implicit_provider_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "explicit_default_provider_table" {
  provider   = google
  dataset_id = "implicit_provider_data"
  table_id   = "explicit_default_provider_table"
}

# External dataset: its data stays in the external source, so it has no
# default key to set and is out of scope
resource "google_bigquery_dataset" "federated" {
  project    = "analytics-prod"
  dataset_id = "federated_data"
  location   = "US"

  external_dataset_reference {
    external_source = "aws-glue://arn:aws:glue:us-east-1:111122223333:database/sales"
    connection      = "projects/analytics-prod/locations/aws-us-east-1/connections/glue"
  }
}

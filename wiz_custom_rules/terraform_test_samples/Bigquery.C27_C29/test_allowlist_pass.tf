# Bigquery.C29 (bigquery_cmek_encryption) - allowlist - COMPLIANT

resource "google_bigquery_dataset" "secured" {
  dataset_id = "secured_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "secured_table" {
  dataset_id = google_bigquery_dataset.secured.dataset_id
  table_id   = "secured_table"

  encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key/cryptoKeyVersions/5"
  }
}

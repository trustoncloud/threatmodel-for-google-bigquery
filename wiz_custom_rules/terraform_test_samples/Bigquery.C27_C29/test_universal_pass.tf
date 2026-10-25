# Bigquery.C29 (bigquery_cmek_encryption) - universal - COMPLIANT

resource "google_bigquery_dataset" "encrypted" {
  dataset_id = "encrypted_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/p/locations/us/keyRings/r/cryptoKeys/k"
  }
}

resource "google_bigquery_table" "encrypted_table" {
  dataset_id = google_bigquery_dataset.encrypted.dataset_id
  table_id   = "encrypted_table"

  encryption_configuration {
    kms_key_name = "projects/p/locations/us/keyRings/r/cryptoKeys/k"
  }
}

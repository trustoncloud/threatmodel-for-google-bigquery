# Bigquery.C29 (bigquery_cmek_encryption) - allowlist - VIOLATING

# Dataset with an unauthorized key: 1 finding
resource "google_bigquery_dataset" "rogue_key" {
  dataset_id = "rogue_key_data"
  location   = "US"

  default_encryption_configuration {
    kms_key_name = "projects/rogue-project/locations/us/keyRings/x/cryptoKeys/rogue-key"
  }
}

# Table without CMEK: 1 finding
resource "google_bigquery_table" "plain_table" {
  dataset_id = google_bigquery_dataset.rogue_key.dataset_id
  table_id   = "plain_table"
}

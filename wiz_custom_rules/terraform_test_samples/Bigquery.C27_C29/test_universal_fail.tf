# Bigquery.C29 (bigquery_cmek_encryption) - universal - VIOLATING

# Dataset without CMEK: 1 finding
resource "google_bigquery_dataset" "plain" {
  dataset_id = "plain_data"
  location   = "US"
}

# Table without CMEK: 1 finding
resource "google_bigquery_table" "plain_table" {
  dataset_id = google_bigquery_dataset.plain.dataset_id
  table_id   = "plain_table"
}

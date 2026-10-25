# Bigquery.C19 (bigquery_authorized_configuration) - allowlist - VIOLATING

# Unauthorized location: 1 finding
resource "google_bigquery_dataset" "wrong_region" {
  dataset_id = "wrong_region_data"
  location   = "europe-west1"
}

# Expiration set to an unauthorized value: 1 finding
resource "google_bigquery_dataset" "odd_expiry" {
  dataset_id                  = "odd_expiry_data"
  location                    = "US"
  default_table_expiration_ms = 9999999999
}

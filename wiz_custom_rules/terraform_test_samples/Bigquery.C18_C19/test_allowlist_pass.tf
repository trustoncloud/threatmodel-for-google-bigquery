# Bigquery.C19 (bigquery_authorized_configuration) - allowlist - COMPLIANT

resource "google_bigquery_dataset" "conforming" {
  dataset_id                      = "conforming_data"
  location                        = "US"
  default_table_expiration_ms     = 5184000000
  default_partition_expiration_ms = 5184000000
}

# Expirations unset: only the universal leg polices absence
resource "google_bigquery_dataset" "no_expiry" {
  dataset_id = "no_expiry_data"
  location   = "us-central1"
}

# Location names are case-insensitive: "us" is the authorized US multi-region
resource "google_bigquery_dataset" "lowercase_us" {
  dataset_id = "lowercase_us_data"
  location   = "us"
}

# Location unset: defaults to the authorized US multi-region
resource "google_bigquery_dataset" "default_location" {
  dataset_id = "default_location_data"
}

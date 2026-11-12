# Bigquery.C34 (bigquery_table_expiration) - universal - COMPLIANT

resource "google_bigquery_table" "expiring" {
  dataset_id      = "analytics_data"
  table_id        = "expiring_table"
  expiration_time = 1800000000000
}

# A dataset with a default table expiration, and tables that inherit it
resource "google_bigquery_dataset" "retained" {
  project                     = "analytics-prod"
  dataset_id                  = "retained_data"
  location                    = "US"
  default_table_expiration_ms = 2592000000
}

# Tied by a reference to the dataset resource
resource "google_bigquery_table" "inherits_by_reference" {
  project    = "analytics-prod"
  dataset_id = google_bigquery_dataset.retained.dataset_id
  table_id   = "inherits_by_reference"
}

# Tied by the same literal project and dataset ID
resource "google_bigquery_table" "inherits_by_id" {
  project    = "analytics-prod"
  dataset_id = "retained_data"
  table_id   = "inherits_by_id"
}

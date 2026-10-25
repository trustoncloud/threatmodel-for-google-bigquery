# Bigquery.C19 (bigquery_authorized_configuration) - universal - VIOLATING

# No default table expiration: 1 finding
resource "google_bigquery_dataset" "forever" {
  dataset_id = "forever_data"
  location   = "US"
}

# Time travel beyond the maximum: 1 finding
# (provider accepts 48-168, so an out-of-policy value can still appear in IaC)
resource "google_bigquery_dataset" "long_travel" {
  dataset_id                  = "long_travel_data"
  location                    = "US"
  default_table_expiration_ms = 2592000000
  max_time_travel_hours       = 720
}

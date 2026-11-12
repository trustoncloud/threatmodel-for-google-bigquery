# Bigquery.C19 (bigquery_authorized_configuration) - universal - VIOLATING

# No default table expiration: 1 finding
resource "google_bigquery_dataset" "forever" {
  dataset_id = "forever_data"
  location   = "US"
}

# Time travel beyond the maximum: 1 finding
# BigQuery accepts 48 to 168 hours and the rule's default maximum is 168, so
# no value the platform accepts is above it. 720 proves the comparison only:
# an apply with this value is rejected.
resource "google_bigquery_dataset" "long_travel" {
  dataset_id                  = "long_travel_data"
  location                    = "US"
  default_table_expiration_ms = 2592000000
  max_time_travel_hours       = 720
}

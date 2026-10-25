# Bigquery.C52 (bigquery_time_travel) - universal - VIOLATING

# Time travel window below the 48h minimum: 1 finding
resource "google_bigquery_dataset" "short_travel" {
  dataset_id            = "short_travel_data"
  location              = "US"
  max_time_travel_hours = 24
}

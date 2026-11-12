# Bigquery.C52 (bigquery_time_travel) - universal - VIOLATING

# Time travel window below the 48h minimum: 1 finding
# BigQuery accepts 48 to 168 hours and the rule's default minimum is 48, so
# no value the platform accepts is below it. 24 proves the comparison only:
# an apply with this value is rejected.
resource "google_bigquery_dataset" "short_travel" {
  dataset_id            = "short_travel_data"
  location              = "US"
  max_time_travel_hours = 24
}

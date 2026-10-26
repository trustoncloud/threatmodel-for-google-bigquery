# Bigquery.C52 (bigquery_time_travel) - universal - COMPLIANT

resource "google_bigquery_dataset" "standard_travel" {
  dataset_id            = "standard_travel_data"
  location              = "US"
  max_time_travel_hours = 168
}

# Attribute omitted: GCP applies the 168h default
resource "google_bigquery_dataset" "default_travel" {
  dataset_id = "default_travel_data"
  location   = "US"
}

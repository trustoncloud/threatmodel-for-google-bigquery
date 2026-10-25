# Bigquery.C19 (bigquery_authorized_configuration) - universal - COMPLIANT

resource "google_bigquery_dataset" "baseline" {
  dataset_id                  = "baseline_data"
  location                    = "US"
  default_table_expiration_ms = 2592000000
  max_time_travel_hours       = 168
}

# Bigquery.C34 (bigquery_table_expiration) - universal - COMPLIANT

resource "google_bigquery_table" "expiring" {
  dataset_id      = "analytics_data"
  table_id        = "expiring_table"
  expiration_time = 1800000000000
}

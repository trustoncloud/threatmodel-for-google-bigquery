# Bigquery.C34 (bigquery_table_expiration) - universal - VIOLATING

# No expiration time (infinite retention): 1 finding
resource "google_bigquery_table" "forever" {
  dataset_id = "analytics_data"
  table_id   = "forever_table"
}

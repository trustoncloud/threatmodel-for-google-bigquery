# Bigquery.C83 (bigquery_table_availability) - universal - VIOLATING

# Partitioned table without a partition filter requirement: 1 finding
resource "google_bigquery_table" "open_scan" {
  dataset_id = "analytics_data"
  table_id   = "open_scan_table"

  time_partitioning {
    type = "DAY"
  }
}

# Bigquery.C83 (bigquery_table_availability) - universal - COMPLIANT

# Partitioned with the top-level flag
resource "google_bigquery_table" "filtered" {
  dataset_id               = "analytics_data"
  table_id                 = "filtered_table"
  require_partition_filter = true

  time_partitioning {
    type = "DAY"
  }
}

# Partitioned with the (deprecated) nested flag
resource "google_bigquery_table" "legacy_filtered" {
  dataset_id = "analytics_data"
  table_id   = "legacy_filtered_table"

  time_partitioning {
    type                     = "DAY"
    require_partition_filter = true
  }
}

# Not partitioned: out of scope
resource "google_bigquery_table" "unpartitioned" {
  dataset_id = "analytics_data"
  table_id   = "unpartitioned_table"
}

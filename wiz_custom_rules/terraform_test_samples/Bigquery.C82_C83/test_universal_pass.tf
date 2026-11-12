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

# Hive-partitioned external table with the nested flag
resource "google_bigquery_table" "hive_filtered" {
  dataset_id = "analytics_data"
  table_id   = "hive_filtered_table"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://example-data-lake/events/*"]

    hive_partitioning_options {
      mode                     = "AUTO"
      source_uri_prefix        = "gs://example-data-lake/events/"
      require_partition_filter = true
    }
  }
}

# External table with no Hive partitioning: out of scope
resource "google_bigquery_table" "external_flat" {
  dataset_id = "analytics_data"
  table_id   = "external_flat_table"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris   = ["gs://example-data-lake/flat/*.csv"]
  }
}

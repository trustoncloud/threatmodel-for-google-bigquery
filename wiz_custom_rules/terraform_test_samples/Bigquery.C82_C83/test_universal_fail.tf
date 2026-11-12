# Bigquery.C83 (bigquery_table_availability) - universal - VIOLATING

# Partitioned table without a partition filter requirement: 1 finding
resource "google_bigquery_table" "open_scan" {
  dataset_id = "analytics_data"
  table_id   = "open_scan_table"

  time_partitioning {
    type = "DAY"
  }
}

# Hive-partitioned external table with no partition filter requirement: 1 finding
resource "google_bigquery_table" "hive_open_scan" {
  dataset_id = "analytics_data"
  table_id   = "hive_open_scan_table"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://example-data-lake/events/*"]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://example-data-lake/events/"
    }
  }
}

# Hive-partitioned external table that turns the requirement off: 1 finding
resource "google_bigquery_table" "hive_filter_off" {
  dataset_id = "analytics_data"
  table_id   = "hive_filter_off_table"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://example-data-lake/orders/*"]

    hive_partitioning_options {
      mode                     = "AUTO"
      source_uri_prefix        = "gs://example-data-lake/orders/"
      require_partition_filter = false
    }
  }
}

# The top-level flag does not cover Hive partitions; the nested one is missing: 1 finding
resource "google_bigquery_table" "hive_top_level_only" {
  dataset_id               = "analytics_data"
  table_id                 = "hive_top_level_only_table"
  require_partition_filter = true

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://example-data-lake/clicks/*"]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://example-data-lake/clicks/"
    }
  }
}

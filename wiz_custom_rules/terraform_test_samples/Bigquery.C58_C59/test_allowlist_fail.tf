# Bigquery.C59 (bigquery_metadata_cache) - allowlist - VIOLATING

# Staleness below the 30-minute minimum: 1 finding
resource "google_bigquery_table" "too_fresh" {
  dataset_id    = "analytics_data"
  table_id      = "too_fresh"
  max_staleness = "0-0 0 0:10:0"

  external_data_configuration {
    autodetect          = true
    connection_id       = "my-connection"
    source_format       = "PARQUET"
    source_uris         = ["gs://trusted-corp-lake/table/*"]
    metadata_cache_mode = "AUTOMATIC"
  }
}

# Cache enabled without max_staleness: 1 finding
resource "google_bigquery_table" "no_staleness" {
  dataset_id = "analytics_data"
  table_id   = "no_staleness"

  external_data_configuration {
    autodetect          = true
    connection_id       = "my-connection"
    source_format       = "PARQUET"
    source_uris         = ["gs://trusted-corp-lake/table/*"]
    metadata_cache_mode = "MANUAL"
  }
}

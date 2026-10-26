# Bigquery.C59 (bigquery_metadata_cache) - allowlist - COMPLIANT

resource "google_bigquery_table" "cached_biglake" {
  dataset_id    = "analytics_data"
  table_id      = "cached_biglake"
  max_staleness = "0-0 0 8:0:0"

  external_data_configuration {
    autodetect          = true
    connection_id       = "my-connection"
    source_format       = "PARQUET"
    source_uris         = ["gs://trusted-corp-lake/table/*"]
    metadata_cache_mode = "AUTOMATIC"
  }
}

# Cache not configured: out of scope for this control
resource "google_bigquery_table" "plain_external" {
  dataset_id = "analytics_data"
  table_id   = "plain_external"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris   = ["gs://trusted-corp-lake/raw/*.csv"]
  }
}

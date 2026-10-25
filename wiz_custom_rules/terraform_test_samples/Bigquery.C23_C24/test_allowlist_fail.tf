# Bigquery.C24 (bigquery_authorized_data_flow) - allowlist - VIOLATING

# External table reading an unauthorized bucket: 1 finding
resource "google_bigquery_table" "shadow_table" {
  dataset_id = "analytics_data"
  table_id   = "shadow_table"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris   = ["gs://unknown-vendor-drop/raw/*.csv"]
  }
}

# Extract job writing to an unauthorized destination: 1 finding
resource "google_bigquery_job" "exfil_extract" {
  job_id = "exfil_extract"

  extract {
    destination_uris = ["gs://personal-backup-bucket/dump-*.json"]

    source_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

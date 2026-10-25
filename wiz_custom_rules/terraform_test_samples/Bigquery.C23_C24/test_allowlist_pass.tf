# Bigquery.C24 (bigquery_authorized_data_flow) - allowlist - COMPLIANT

resource "google_bigquery_table" "lake_table" {
  dataset_id = "analytics_data"
  table_id   = "lake_table"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://my-corp-data-lake/facts/*"]
  }
}

resource "google_bigquery_job" "load_from_partner" {
  job_id = "load_from_partner"

  load {
    source_uris = ["gs://partner-upload-bucket/incoming/*.csv"]

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "partner_feed"
    }
  }
}

resource "google_bigquery_job" "extract_to_lake" {
  job_id = "extract_to_lake"

  extract {
    destination_uris = ["gs://my-corp-data-lake/exports/out-*.avro"]

    source_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

# Bigquery.C55 (bigquery_job_config) - allowlist - COMPLIANT

resource "google_bigquery_job" "bounded_query" {
  job_id = "bounded_query"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "10000000000"
  }
}

resource "google_bigquery_job" "strict_load" {
  job_id = "strict_load"

  load {
    source_uris           = ["gs://my-corp-data-lake/incoming/*.csv"]
    ignore_unknown_values = false

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "orders"
    }
  }
}

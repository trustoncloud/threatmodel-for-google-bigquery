# Bigquery.C55 (bigquery_job_config) - allowlist - VIOLATING

# Query job without a byte limit: 1 finding
resource "google_bigquery_job" "unbounded_query" {
  job_id = "unbounded_query"

  query {
    query = "SELECT * FROM analytics_data.orders"
  }
}

# Load job dropping unknown values: 1 finding
resource "google_bigquery_job" "lossy_load" {
  job_id = "lossy_load"

  load {
    source_uris           = ["gs://my-corp-data-lake/incoming/*.csv"]
    ignore_unknown_values = true

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "orders"
    }
  }
}

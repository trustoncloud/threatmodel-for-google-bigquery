# Bigquery.C55 (bigquery_job_config) - universal - VIOLATING

# Query job without a byte limit: 1 finding
resource "google_bigquery_job" "unbounded_query" {
  job_id = "unbounded_query"

  query {
    query = "SELECT * FROM analytics_data.orders"
  }
}

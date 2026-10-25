# Bigquery.C55 (bigquery_job_config) - universal - COMPLIANT

resource "google_bigquery_job" "bounded_query" {
  job_id = "bounded_query"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "10000000000"
  }
}

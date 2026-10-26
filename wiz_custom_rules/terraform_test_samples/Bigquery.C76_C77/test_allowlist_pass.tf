# Bigquery.C77 (bigquery_job_safety_config) - allowlist - COMPLIANT

resource "google_bigquery_job" "append_only" {
  job_id = "append_only"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"
    write_disposition    = "WRITE_APPEND"
  }
}

# write_disposition omitted: API default WRITE_EMPTY is authorized
resource "google_bigquery_job" "default_write" {
  job_id = "default_write"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"
  }
}

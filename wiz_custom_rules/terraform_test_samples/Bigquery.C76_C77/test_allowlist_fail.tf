# Bigquery.C77 (bigquery_job_safety_config) - allowlist - VIOLATING

# Destructive write mode: 1 finding
resource "google_bigquery_job" "truncating" {
  job_id = "truncating"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"
    write_disposition    = "WRITE_TRUNCATE"
  }
}

# Schema drift enabled: 1 finding
resource "google_bigquery_job" "drifting" {
  job_id = "drifting"

  query {
    query                 = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed  = "1000000000"
    write_disposition     = "WRITE_APPEND"
    schema_update_options = ["ALLOW_FIELD_ADDITION"]
  }
}

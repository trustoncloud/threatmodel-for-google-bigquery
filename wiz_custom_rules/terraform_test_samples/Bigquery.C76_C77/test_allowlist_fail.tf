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

# A create mode set from a variable with no default is not known until apply: 1 finding
variable "create_mode" {
  type = string
}

resource "google_bigquery_job" "create_mode_unknown" {
  job_id = "create_mode_unknown"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"
    write_disposition    = "WRITE_APPEND"
    create_disposition   = var.create_mode

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "orders_copy"
    }
  }
}

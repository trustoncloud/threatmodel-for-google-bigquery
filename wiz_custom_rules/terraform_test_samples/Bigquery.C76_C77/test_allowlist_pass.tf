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

# A job that writes only to a table that already exists
resource "google_bigquery_job" "create_never" {
  job_id = "create_never"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"
    write_disposition    = "WRITE_APPEND"
    create_disposition   = "CREATE_NEVER"

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "orders_copy"
    }
  }
}

# create_disposition omitted: API default CREATE_IF_NEEDED is authorized
resource "google_bigquery_job" "default_create" {
  job_id = "default_create"

  query {
    query                = "SELECT * FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"
    write_disposition    = "WRITE_APPEND"

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "orders_copy"
    }
  }
}

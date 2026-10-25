# Bigquery.C72 (bigquery_udf_bucket) - allowlist - COMPLIANT

resource "google_bigquery_job" "trusted_udf" {
  job_id = "trusted_udf"

  query {
    query                = "SELECT my_udf(col) FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"

    user_defined_function_resources {
      resource_uri = "gs://my-corp-trusted-scripts/udfs/parse.js"
    }

    user_defined_function_resources {
      inline_code = "function tiny(x) { return x; }"
    }
  }
}

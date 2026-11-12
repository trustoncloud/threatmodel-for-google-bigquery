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

# Lookalikes of the trusted locations: a bucket whose name starts with a
# trusted bucket's name (twice), a folder next to the trusted folder, and a
# file above the trusted folder: 4 findings
resource "google_bigquery_job" "lookalike_udf" {
  job_id = "lookalike_udf"

  query {
    query                = "SELECT my_udf(col) FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"

    user_defined_function_resources {
      resource_uri = "gs://my-corp-trusted-scripts-rogue/udf.js"
    }

    user_defined_function_resources {
      resource_uri = "gs://my-corp-trusted-scriptsx/udf.js"
    }

    user_defined_function_resources {
      resource_uri = "gs://partner-lib-bucket/v1-old/lib.js"
    }

    user_defined_function_resources {
      resource_uri = "gs://partner-lib-bucket/lib.js"
    }
  }
}

# A location set from a variable with no default is not known until apply: 1 finding
variable "udf_bucket" {
  type = string
}

resource "google_bigquery_job" "unresolved_udf" {
  job_id = "unresolved_udf"

  query {
    query                = "SELECT my_udf(col) FROM analytics_data.orders"
    maximum_bytes_billed = "1000000000"

    user_defined_function_resources {
      resource_uri = "gs://${var.udf_bucket}/udfs/parse.js"
    }
  }
}

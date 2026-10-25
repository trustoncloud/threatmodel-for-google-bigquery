# Bigquery.C40 (bigquery_omni_governance) - allowlist - COMPLIANT

# Native GCP connection: not Omni
resource "google_bigquery_connection" "spanner_link" {
  connection_id = "spanner_link"
  location      = "us"

  cloud_spanner {
    database = "projects/example-project/instances/main/databases/orders"
  }
}

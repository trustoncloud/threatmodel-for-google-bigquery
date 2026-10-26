# Bigquery.C40 (bigquery_omni_governance) - universal - COMPLIANT

# Non-Omni connection
resource "google_bigquery_connection" "cloudsql_link" {
  connection_id = "cloudsql_link"
  location      = "us"

  cloud_sql {
    instance_id = "example-project:us-central1:orders-db"
    database    = "orders"
    type        = "POSTGRES"

    credential {
      username = "bq_reader"
      password = "placeholder"
    }
  }
}

# Org policy keeping the Omni ban enforced
resource "google_organization_policy" "omni_ban" {
  org_id     = "123456789012"
  constraint = "constraints/bigquery.disableBQOmniAWS"

  boolean_policy {
    enforced = true
  }
}

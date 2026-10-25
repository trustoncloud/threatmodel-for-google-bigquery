# Bigquery.C40 (bigquery_omni_governance) - universal - VIOLATING

# Omni connection declared under a universal ban: 1 finding
resource "google_bigquery_connection" "azure_link" {
  connection_id = "azure_link"
  location      = "azure-eastus2"

  azure {
    customer_tenant_id = "00000000-0000-0000-0000-000000000000"
  }
}

# Project-level weakening of the Omni ban: 1 finding
resource "google_project_organization_policy" "omni_escape" {
  project    = "example-project"
  constraint = "constraints/bigquery.disableBQOmniAzure"

  boolean_policy {
    enforced = false
  }
}

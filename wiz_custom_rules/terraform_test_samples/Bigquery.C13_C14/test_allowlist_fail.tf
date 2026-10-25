# Bigquery.C14 (bigquery_row_level_security) - allowlist - VIOLATING

# Public grantee and external domain: 2 findings
resource "google_bigquery_row_access_policy" "leaky_filter" {
  dataset_id       = "analytics_data"
  table_id         = "orders"
  policy_id        = "all_rows"
  filter_predicate = "TRUE"

  grantees = [
    "allAuthenticatedUsers",
    "user:outsider@external-vendor.com"
  ]
}

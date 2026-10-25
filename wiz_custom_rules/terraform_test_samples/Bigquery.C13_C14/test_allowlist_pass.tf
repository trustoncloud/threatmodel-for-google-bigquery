# Bigquery.C14 (bigquery_row_level_security) - allowlist - COMPLIANT

resource "google_bigquery_row_access_policy" "region_filter" {
  dataset_id       = "analytics_data"
  table_id         = "orders"
  policy_id        = "au_region_only"
  filter_predicate = "region = 'AU'"

  grantees = [
    "user:analyst@yourcompany.com",
    "group:regional-team@subsidiary.com",
    "serviceAccount:reporting@example-project.iam.gserviceaccount.com"
  ]
}

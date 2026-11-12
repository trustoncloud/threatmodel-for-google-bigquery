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

# Lookalikes of the approved domains and service accounts from projects that
# are not approved: 8 findings
resource "google_bigquery_row_access_policy" "lookalike_grantees" {
  dataset_id       = "analytics_data"
  table_id         = "orders"
  policy_id        = "lookalikes"
  filter_predicate = "region = 'AU'"

  grantees = [
    "user:intruder@notyourcompany.com",
    "user:x@yourcompany.com.evil.io",
    "group:team@eng.yourcompany.com",
    "user:a@yourcompany.com@evil.io",
    "domain:notyourcompany.com",
    "serviceAccount:reader@untrusted-project.iam.gserviceaccount.com",
    "serviceAccount:reader@my-project-rogue.iam.gserviceaccount.com",
    "serviceAccount:service-111111111111@attacker-proj.iam.gserviceaccount.com",
  ]
}

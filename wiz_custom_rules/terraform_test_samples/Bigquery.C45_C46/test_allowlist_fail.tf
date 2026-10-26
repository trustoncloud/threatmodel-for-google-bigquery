# Bigquery.C46 (bigquery_data_policy_iam) - allowlist - VIOLATING

# Unauthorized member on a masking policy: 1 finding
resource "google_bigquery_datapolicy_data_policy_iam_member" "contractor" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  member         = "user:contractor@external-vendor.com"
}

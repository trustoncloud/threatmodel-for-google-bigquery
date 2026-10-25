# Bigquery.C105 (bigquery_subscription_governance) - allowlist - VIOLATING

# Public subscriber grant: 1 finding
resource "google_bigquery_analytics_hub_data_exchange_iam_member" "public_grant" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

# Subscriber from an unauthorized domain via a binding: 1 finding
resource "google_bigquery_analytics_hub_listing_iam_binding" "vendor_subscribers" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  role             = "roles/analyticshub.admin"
  members = [
    "group:consumers@yourcompany.com",
    "user:outsider@external-vendor.com"
  ]
}

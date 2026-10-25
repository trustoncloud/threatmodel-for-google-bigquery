# Bigquery.C105 (bigquery_subscription_governance) - allowlist - COMPLIANT

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "partner_subscriber" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  member           = "group:data-consumers@yourcompany.com"
}

resource "google_bigquery_analytics_hub_listing_iam_binding" "listing_subscribers" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  members = [
    "user:analyst@yourcompany.com",
    "serviceAccount:etl@partner-domain.com"
  ]
}

# Viewer role is not subscriber-capable: out of scope
resource "google_bigquery_analytics_hub_data_exchange_iam_member" "viewer" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.viewer"
  member           = "user:guest@external.com"
}

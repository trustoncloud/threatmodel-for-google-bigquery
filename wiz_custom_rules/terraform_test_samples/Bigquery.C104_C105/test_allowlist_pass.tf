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
    "serviceAccount:etl@my-project.iam.gserviceaccount.com"
  ]
}

# Viewer role is not subscriber-capable: out of scope
resource "google_bigquery_analytics_hub_data_exchange_iam_member" "viewer" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.viewer"
  member           = "user:guest@external.com"
}

# A policy that takes its bindings from a data source in this file, with
# approved subscribers only
data "google_iam_policy" "subscribers" {
  binding {
    role = "roles/analyticshub.subscriber"
    members = [
      "group:data-consumers@yourcompany.com",
      "user:analyst@partner-domain.com",
    ]
  }
}

resource "google_bigquery_analytics_hub_listing_iam_policy" "listing_policy" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  policy_data      = data.google_iam_policy.subscribers.policy_data
}

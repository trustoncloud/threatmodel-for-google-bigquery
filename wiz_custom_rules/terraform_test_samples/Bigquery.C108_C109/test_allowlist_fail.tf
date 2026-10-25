# Bigquery.C109 (bigquery_subscription_ingress) - allowlist - VIOLATING

# Subscription to an unauthorized exchange: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "shadow" {
  data_exchange_id = "unknown_marketplace_share"
  listing_id       = "tempting_dataset"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_shadow_data"
      project_id = "example-project"
    }
  }
}

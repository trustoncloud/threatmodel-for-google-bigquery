# Bigquery.C102 (bigquery_listing_content_check) - denylist - VIOLATING

# Email address in the description: 1 finding
resource "google_bigquery_analytics_hub_listing" "leaky_metadata" {
  data_exchange_id = "internal_analytics"
  listing_id       = "leaky_listing"
  display_name     = "Order Analytics"
  location         = "us"
  description      = "Contact data-owner@example.com for access"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

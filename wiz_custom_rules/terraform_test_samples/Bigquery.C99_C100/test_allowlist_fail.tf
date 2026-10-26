# Bigquery.C100 (bigquery_listing_security) - allowlist - VIOLATING

# Public discovery + unrestricted export + missing docs: 4 findings
resource "google_bigquery_analytics_hub_listing" "exposed" {
  data_exchange_id = "internal_analytics"
  listing_id       = "exposed_listing"
  display_name     = "Exposed Listing"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

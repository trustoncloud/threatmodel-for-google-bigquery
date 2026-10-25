# Bigquery.C102 (bigquery_listing_content_check) - denylist - COMPLIANT

resource "google_bigquery_analytics_hub_listing" "clean_metadata" {
  data_exchange_id = "internal_analytics"
  listing_id       = "clean_listing"
  display_name     = "Order Analytics"
  location         = "us"
  description      = "Aggregated order metrics by region"
  documentation    = "See the data catalog entry for schema details"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

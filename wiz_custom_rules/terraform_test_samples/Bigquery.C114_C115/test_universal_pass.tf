# Bigquery.C115 (bigquery_listing_restricted_export) - universal - COMPLIANT

resource "google_bigquery_analytics_hub_listing" "locked_down" {
  data_exchange_id = "internal_analytics"
  listing_id       = "locked_listing"
  display_name     = "Locked Listing"
  location         = "us"
  description      = "View-only sharing"

  restricted_export_config {
    enabled               = true
    restrict_query_result = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

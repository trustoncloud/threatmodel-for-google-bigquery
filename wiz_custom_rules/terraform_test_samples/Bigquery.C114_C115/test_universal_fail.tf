# Bigquery.C115 (bigquery_listing_restricted_export) - universal - VIOLATING

# No restricted export at all: 1 finding
resource "google_bigquery_analytics_hub_listing" "open_export" {
  data_exchange_id = "internal_analytics"
  listing_id       = "open_listing"
  display_name     = "Open Listing"
  location         = "us"
  description      = "Exportable"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# Enabled but query results still exportable: 1 finding
resource "google_bigquery_analytics_hub_listing" "partial_export" {
  data_exchange_id = "internal_analytics"
  listing_id       = "partial_listing"
  display_name     = "Partial Listing"
  location         = "us"
  description      = "Partially restricted"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

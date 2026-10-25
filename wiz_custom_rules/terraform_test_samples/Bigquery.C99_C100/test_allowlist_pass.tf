# Bigquery.C100 (bigquery_listing_security) - allowlist - COMPLIANT

resource "google_bigquery_analytics_hub_listing" "governed" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  display_name     = "Governed Listing"
  location         = "us"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/governed-listing"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# Allowlisted exportable reference listing
resource "google_bigquery_analytics_hub_listing" "reference" {
  data_exchange_id = "internal_analytics"
  listing_id       = "public_holidays"
  display_name     = "Public Holidays"
  location         = "us"
  description      = "Reference calendar data"
  documentation    = "https://wiki.example.com/data/holidays"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/reference_data"
  }
}

# Bigquery.C112 (bigquery_contact_domain_check) - allowlist - VIOLATING

# No primary contact: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "contactless" {
  data_exchange_id = "contactless_exchange"
  display_name     = "Contactless Exchange"
  location         = "us"
}

# Contact from an unauthorized domain: 1 finding
resource "google_bigquery_analytics_hub_listing" "vendor_listing" {
  data_exchange_id = "contactless_exchange"
  listing_id       = "vendor_listing"
  display_name     = "Vendor Listing"
  location         = "us"
  description      = "Vendor data"
  primary_contact  = "someone@badvendor.com"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

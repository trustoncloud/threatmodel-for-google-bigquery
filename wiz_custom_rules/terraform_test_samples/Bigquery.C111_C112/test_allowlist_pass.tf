# Bigquery.C112 (bigquery_contact_domain_check) - allowlist - COMPLIANT

resource "google_bigquery_analytics_hub_data_exchange" "governed" {
  data_exchange_id = "governed_exchange"
  display_name     = "Governed Exchange"
  location         = "us"
  primary_contact  = "data-gov@yourcompany.com"
}

resource "google_bigquery_analytics_hub_listing" "governed_listing" {
  data_exchange_id = "governed_exchange"
  listing_id       = "governed_listing"
  display_name     = "Governed Listing"
  location         = "us"
  description      = "Curated data"
  primary_contact  = "data-owners@subsidiary.com"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

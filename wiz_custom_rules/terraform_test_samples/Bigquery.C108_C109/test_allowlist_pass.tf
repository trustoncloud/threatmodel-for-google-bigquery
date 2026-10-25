# Bigquery.C109 (bigquery_subscription_ingress) - allowlist - COMPLIANT

resource "google_bigquery_analytics_hub_listing_subscription" "governed" {
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_partner_sales"
      project_id = "example-project"
    }
  }
}

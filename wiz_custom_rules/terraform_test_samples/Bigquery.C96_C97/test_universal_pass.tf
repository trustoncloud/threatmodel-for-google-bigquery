# Bigquery.C97 (bigquery_exchange_exposure) - universal - COMPLIANT

resource "google_bigquery_analytics_hub_data_exchange" "internal" {
  data_exchange_id = "internal_analytics"
  display_name     = "Internal Analytics"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}

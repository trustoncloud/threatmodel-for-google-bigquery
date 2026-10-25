# Bigquery.C97 (bigquery_exchange_exposure) - universal - VIOLATING

# Published exchange: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "published" {
  data_exchange_id = "published_share"
  display_name     = "Published Share"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

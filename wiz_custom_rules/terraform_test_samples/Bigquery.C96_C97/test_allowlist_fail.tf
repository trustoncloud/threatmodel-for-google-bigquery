# Bigquery.C97 (bigquery_exchange_exposure) - allowlist - VIOLATING

# Published to the marketplace without authorization: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "rogue_public" {
  data_exchange_id = "rogue_public_share"
  display_name     = "Rogue Public Share"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

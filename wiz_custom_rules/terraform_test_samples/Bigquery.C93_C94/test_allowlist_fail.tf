# Bigquery.C94 (bigquery_clean_room_enforcement) - allowlist - VIOLATING

# Required exchange running as a standard exchange: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "leaky_sensitive" {
  data_exchange_id = "pii_clean_room"
  display_name     = "PII Sharing"
  location         = "us"
  description      = "Should be a clean room"
}

# Bigquery.C97 (bigquery_exchange_exposure) - allowlist - COMPLIANT

# Private exchange
resource "google_bigquery_analytics_hub_data_exchange" "internal" {
  data_exchange_id = "internal_analytics"
  display_name     = "Internal Analytics"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}

# Published exchange explicitly allowlisted
resource "google_bigquery_analytics_hub_data_exchange" "official" {
  data_exchange_id = "official_public_dataset"
  display_name     = "Official Public Dataset"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

# discovery_type omitted: not published
resource "google_bigquery_analytics_hub_data_exchange" "unset" {
  data_exchange_id = "quiet_exchange"
  display_name     = "Quiet Exchange"
  location         = "us"
}

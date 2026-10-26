# Bigquery.C94 (bigquery_clean_room_enforcement) - universal - VIOLATING

# Standard exchange (default sharing environment): 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "open_share" {
  data_exchange_id = "team_reference_data"
  display_name     = "Team Reference Data"
  location         = "us"
  description      = "Internal reference data"

  sharing_environment_config {
    default_exchange_config {}
  }
}

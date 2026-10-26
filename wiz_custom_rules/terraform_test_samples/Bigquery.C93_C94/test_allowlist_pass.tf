# Bigquery.C94 (bigquery_clean_room_enforcement) - allowlist - COMPLIANT

# Required exchange configured as a Data Clean Room
resource "google_bigquery_analytics_hub_data_exchange" "sensitive" {
  data_exchange_id = "sensitive_partner_exchange"
  display_name     = "Sensitive Partner Exchange"
  location         = "us"
  description      = "Clean room for partner analytics"

  sharing_environment_config {
    dcr_exchange_config {}
  }
}

# Standard exchange not on the required list
resource "google_bigquery_analytics_hub_data_exchange" "open_share" {
  data_exchange_id = "team_reference_data"
  display_name     = "Team Reference Data"
  location         = "us"
  description      = "Internal reference data"
}

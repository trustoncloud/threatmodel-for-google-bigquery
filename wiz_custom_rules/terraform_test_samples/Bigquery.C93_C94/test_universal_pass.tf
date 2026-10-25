# Bigquery.C94 (bigquery_clean_room_enforcement) - universal - COMPLIANT

resource "google_bigquery_analytics_hub_data_exchange" "clean_room" {
  data_exchange_id = "partner_clean_room"
  display_name     = "Partner Clean Room"
  location         = "us"
  description      = "Privacy-safe sharing"

  sharing_environment_config {
    dcr_exchange_config {}
  }
}

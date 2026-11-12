# Bigquery.C94 (bigquery_clean_room_enforcement) - allowlist - VIOLATING

# Required exchange running as a standard exchange: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "leaky_sensitive" {
  project          = "my-other-project"
  data_exchange_id = "pii_clean_room"
  display_name     = "PII Sharing"
  location         = "us"
  description      = "Should be a clean room"
}

# Location written in upper case names the same exchange: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "upper_case_location" {
  project          = "my-project"
  data_exchange_id = "sensitive_partner_exchange"
  display_name     = "Sensitive Partner Exchange"
  location         = "US"

  sharing_environment_config {
    default_exchange_config {}
  }
}

# No project written in the resource (left out, or taken from a variable):
# the location and ID match a required exchange, so it is held to the
# requirement: 2 findings
resource "google_bigquery_analytics_hub_data_exchange" "no_project" {
  data_exchange_id = "pii_clean_room"
  display_name     = "PII Sharing"
  location         = "us"
}

variable "exchange_project" {
  type    = string
  default = "my-project"
}

resource "google_bigquery_analytics_hub_data_exchange" "variable_project" {
  project          = var.exchange_project
  data_exchange_id = "sensitive_partner_exchange"
  display_name     = "Sensitive Partner Exchange"
  location         = "us"
}

# An exchange ID set from a variable with no default is not known until
# apply. Its project and location match a required exchange, so it is held
# to the requirement: 1 finding
variable "exchange_id" {
  type = string
}

resource "google_bigquery_analytics_hub_data_exchange" "variable_id" {
  project          = "my-project"
  data_exchange_id = var.exchange_id
  display_name     = "Partner Exchange"
  location         = "us"
}

# Bigquery.C94 (bigquery_clean_room_enforcement) - allowlist - COMPLIANT

# Required exchange configured as a Data Clean Room
resource "google_bigquery_analytics_hub_data_exchange" "sensitive" {
  project          = "my-project"
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
  project          = "my-project"
  data_exchange_id = "team_reference_data"
  display_name     = "Team Reference Data"
  location         = "us"
  description      = "Internal reference data"
}

# A required exchange's ID in a project or location that is not on the
# required list, and a near name: standard exchanges are allowed there
resource "google_bigquery_analytics_hub_data_exchange" "same_id_other_project" {
  project          = "sandbox-project"
  data_exchange_id = "sensitive_partner_exchange"
  display_name     = "Sandbox Exchange"
  location         = "us"
}

resource "google_bigquery_analytics_hub_data_exchange" "same_id_other_location" {
  project          = "my-project"
  data_exchange_id = "sensitive_partner_exchange"
  display_name     = "Regional Exchange"
  location         = "europe-west1"
}

resource "google_bigquery_analytics_hub_data_exchange" "near_name" {
  project          = "my-other-project"
  data_exchange_id = "pii_clean_room_2"
  display_name     = "Second Exchange"
  location         = "us"
}

# No project written in the resource, and the location differs from every
# required exchange with this ID
resource "google_bigquery_analytics_hub_data_exchange" "no_project_other_location" {
  data_exchange_id = "pii_clean_room"
  display_name     = "Regional Exchange"
  location         = "asia-southeast1"
}

# An exchange ID set from a variable with no default: a Data Clean Room
# meets the requirement whatever its ID, and no required exchange lives in
# the sandbox project
variable "clean_room_exchange_id" {
  type = string
}

resource "google_bigquery_analytics_hub_data_exchange" "variable_id_clean_room" {
  project          = "my-project"
  data_exchange_id = var.clean_room_exchange_id
  display_name     = "Partner Clean Room"
  location         = "us"

  sharing_environment_config {
    dcr_exchange_config {}
  }
}

resource "google_bigquery_analytics_hub_data_exchange" "variable_id_sandbox" {
  project          = "sandbox-project"
  data_exchange_id = var.clean_room_exchange_id
  display_name     = "Sandbox Exchange"
  location         = "us"
}

# Bigquery.C97 (bigquery_exchange_exposure) - allowlist - VIOLATING

# Published to the marketplace without authorization: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "rogue_public" {
  project          = "my-project"
  data_exchange_id = "rogue_public_share"
  display_name     = "Rogue Public Share"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

# The approved exchange ID in another project, in another location, and a
# near name: 3 findings
resource "google_bigquery_analytics_hub_data_exchange" "other_project" {
  project          = "attacker-project"
  data_exchange_id = "official_public_dataset"
  display_name     = "Official Public Dataset"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

resource "google_bigquery_analytics_hub_data_exchange" "other_location" {
  project          = "my-project"
  data_exchange_id = "official_public_dataset"
  display_name     = "Official Public Dataset"
  location         = "eu"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

resource "google_bigquery_analytics_hub_data_exchange" "near_name" {
  project          = "my-project"
  data_exchange_id = "official_public_dataset_2"
  display_name     = "Official Public Dataset 2"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

# The configuration names the project by its ID, so the project number does
# not match: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "project_number" {
  project          = "111111111111"
  data_exchange_id = "official_public_dataset"
  display_name     = "Official Public Dataset"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

# No project written in the resource (left out, or taken from a variable),
# so the exchange cannot be matched: 2 findings
resource "google_bigquery_analytics_hub_data_exchange" "no_project" {
  data_exchange_id = "official_public_dataset"
  display_name     = "Official Public Dataset"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

variable "exchange_project" {
  type    = string
  default = "attacker-project"
}

resource "google_bigquery_analytics_hub_data_exchange" "variable_project" {
  project          = var.exchange_project
  data_exchange_id = "official_public_dataset"
  display_name     = "Official Public Dataset"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

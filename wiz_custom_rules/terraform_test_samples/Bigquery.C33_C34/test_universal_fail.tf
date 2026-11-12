# Bigquery.C34 (bigquery_table_expiration) - universal - VIOLATING

# No expiration time (infinite retention): 1 finding
resource "google_bigquery_table" "forever" {
  dataset_id = "analytics_data"
  table_id   = "forever_table"
}

# A dataset with no default table expiration gives its table nothing to inherit: 1 finding
resource "google_bigquery_dataset" "unbounded" {
  project    = "analytics-prod"
  dataset_id = "unbounded_data"
  location   = "US"
}

resource "google_bigquery_table" "in_unbounded_dataset" {
  project    = "analytics-prod"
  dataset_id = google_bigquery_dataset.unbounded.dataset_id
  table_id   = "in_unbounded_dataset"
}

# A dataset with a default, and tables that do not inherit it
resource "google_bigquery_dataset" "retained" {
  project                     = "analytics-prod"
  dataset_id                  = "retained_data"
  location                    = "US"
  default_table_expiration_ms = 2592000000
}

# Same dataset ID in another project is another dataset: 1 finding
resource "google_bigquery_table" "other_project_table" {
  project    = "analytics-dev"
  dataset_id = "retained_data"
  table_id   = "other_project_table"
}

# A dataset ID that only starts with the dataset's ID is another dataset: 1 finding
resource "google_bigquery_table" "lookalike_dataset_table" {
  project    = "analytics-prod"
  dataset_id = "retained_data_2"
  table_id   = "lookalike_dataset_table"
}

# A default set from a variable with no default is not known until apply: 1 finding
variable "table_lifetime_ms" {
  type = number
}

resource "google_bigquery_dataset" "variable_default" {
  project                     = "analytics-prod"
  dataset_id                  = "variable_default_data"
  location                    = "US"
  default_table_expiration_ms = var.table_lifetime_ms
}

resource "google_bigquery_table" "in_variable_default_dataset" {
  project    = "analytics-prod"
  dataset_id = google_bigquery_dataset.variable_default.dataset_id
  table_id   = "in_variable_default_dataset"
}

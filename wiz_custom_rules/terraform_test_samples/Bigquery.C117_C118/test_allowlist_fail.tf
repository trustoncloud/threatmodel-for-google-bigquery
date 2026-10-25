# Bigquery.C118 (bigquery_dataset_access_governance) - allowlist - VIOLATING

# Public access + external domain + missing mandatory admin: 3 findings
resource "google_bigquery_dataset" "exposed" {
  dataset_id = "exposed_data"
  location   = "US"

  access {
    role          = "READER"
    special_group = "allAuthenticatedUsers"
  }

  access {
    role          = "READER"
    user_by_email = "contractor@external-vendor.com"
  }
}

# Standalone grant to an unauthorized domain: 1 finding
resource "google_bigquery_dataset_access" "vendor_grant" {
  dataset_id    = google_bigquery_dataset.exposed.dataset_id
  role          = "WRITER"
  user_by_email = "someone@badvendor.com"
}

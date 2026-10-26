# Bigquery.C118 (bigquery_dataset_access_governance) - allowlist - COMPLIANT

# Mandatory admin granted inline
resource "google_bigquery_dataset" "inline_admin" {
  dataset_id = "inline_admin_data"
  location   = "US"

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  access {
    role          = "READER"
    user_by_email = "analyst@yourcompany.com"
  }
}

# Mandatory admin granted through the standalone resource
resource "google_bigquery_dataset" "standalone_admin" {
  dataset_id = "standalone_admin_data"
  location   = "US"
}

resource "google_bigquery_dataset_access" "admin_grant" {
  dataset_id     = google_bigquery_dataset.standalone_admin.dataset_id
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

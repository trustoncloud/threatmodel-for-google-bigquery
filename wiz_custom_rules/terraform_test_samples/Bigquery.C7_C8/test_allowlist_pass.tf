# Bigquery.C8 (bigquery_authorized_access) - allowlist - COMPLIANT

resource "google_bigquery_dataset" "governed" {
  dataset_id = "governed_data"
  location   = "US"

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  access {
    role           = "WRITER"
    group_by_email = "data-team@yourcompany.com"
  }
}

resource "google_bigquery_dataset_access" "admin_reader" {
  dataset_id    = google_bigquery_dataset.governed.dataset_id
  role          = "READER"
  user_by_email = "admin@yourcompany.com"
}

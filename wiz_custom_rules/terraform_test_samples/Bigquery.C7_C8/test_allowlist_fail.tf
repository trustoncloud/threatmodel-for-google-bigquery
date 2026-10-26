# Bigquery.C8 (bigquery_authorized_access) - allowlist - VIOLATING

# Inline entry granting an unauthorized user: 1 finding
resource "google_bigquery_dataset" "leaky" {
  dataset_id = "leaky_data"
  location   = "US"

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    user_by_email = "someone@external-vendor.com"
  }
}

# Standalone grant to an unauthorized routine: 1 finding
resource "google_bigquery_dataset_access" "rogue_routine" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id

  routine {
    project_id = "rogue-proj"
    dataset_id = "rogue_ds"
    routine_id = "exfil_udf"
  }
}

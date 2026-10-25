# Bigquery.C5 (bigquery_backup_labels) - allowlist - COMPLIANT

resource "google_bigquery_dataset" "governed" {
  dataset_id = "governed_data"
  location   = "US"

  labels = {
    backup_policy = "daily"
    env           = "prod"
  }
}

# Bigquery.C5 (bigquery_backup_labels) - allowlist - VIOLATING

# No labels at all: 1 finding
resource "google_bigquery_dataset" "unlabeled" {
  dataset_id = "unlabeled_data"
  location   = "US"
}

# Backup label present but with an unauthorized value: 1 finding
resource "google_bigquery_dataset" "bad_schedule" {
  dataset_id = "bad_schedule_data"
  location   = "US"

  labels = {
    backup_policy = "never"
  }
}

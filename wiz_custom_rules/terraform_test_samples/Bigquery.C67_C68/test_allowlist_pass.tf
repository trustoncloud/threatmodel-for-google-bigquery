# Bigquery.C68 (bigquery_transfer_authorization) - allowlist - COMPLIANT

resource "google_bigquery_data_transfer_config" "nightly_ingest" {
  project                = "my-project"
  display_name           = "nightly-ingest"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  schedule               = "every day 05:00"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    data_path_template              = "gs://trusted-corp-landing/incoming/*.csv"
    destination_table_name_template = "orders"
    file_format                     = "CSV"
    delete_source_files             = "false"
  }
}

# Folder inside an approved bucket, deletion off as a boolean
resource "google_bigquery_data_transfer_config" "archive_ingest" {
  project                = "my-project"
  display_name           = "archive-ingest"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "my_governed_dataset"
  location               = "us"
  service_account_name   = "backup-admin@my-project.iam.gserviceaccount.com"

  params = {
    data_path_template              = "gs://trusted-corp-archive/inbound/2026/*.csv"
    destination_table_name_template = "orders"
    file_format                     = "CSV"
    delete_source_files             = false
  }
}

# Destination taken from an approved dataset declared in the same plan
resource "google_bigquery_dataset" "governed" {
  project    = "my-project"
  dataset_id = "my_governed_dataset"
  location   = "US"
}

resource "google_bigquery_data_transfer_config" "scheduled_rollup" {
  project                = "my-project"
  display_name           = "scheduled-rollup"
  data_source_id         = "scheduled_query"
  destination_dataset_id = google_bigquery_dataset.governed.dataset_id
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    query = "SELECT 1"
  }
}

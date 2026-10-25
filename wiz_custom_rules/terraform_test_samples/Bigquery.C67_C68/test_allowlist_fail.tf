# Bigquery.C68 (bigquery_transfer_authorization) - allowlist - VIOLATING

# Untrusted path + destructive deletion + unauthorized identity: 3 findings
resource "google_bigquery_data_transfer_config" "rogue_ingest" {
  display_name           = "rogue-ingest"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  schedule               = "every day 05:00"
  service_account_name   = "super-admin@my-project.iam.gserviceaccount.com"

  params = {
    data_path_template              = "gs://unknown-vendor-drop/incoming/*.csv"
    destination_table_name_template = "orders"
    file_format                     = "CSV"
    delete_source_files             = "true"
  }
}

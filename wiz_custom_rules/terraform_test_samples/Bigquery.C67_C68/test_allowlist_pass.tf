# Bigquery.C68 (bigquery_transfer_authorization) - allowlist - COMPLIANT

resource "google_bigquery_data_transfer_config" "nightly_ingest" {
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

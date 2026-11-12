# Bigquery.C68 (bigquery_transfer_authorization) - allowlist - VIOLATING

# Untrusted path + destructive deletion + unauthorized identity: 3 findings
resource "google_bigquery_data_transfer_config" "rogue_ingest" {
  project                = "my-project"
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

# Bucket whose name starts with an approved bucket's name: 1 finding
resource "google_bigquery_data_transfer_config" "lookalike_bucket" {
  project                = "my-project"
  display_name           = "lookalike-bucket"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    data_path_template              = "gs://trusted-corp-landing-rogue/incoming/*.csv"
    destination_table_name_template = "orders"
    file_format                     = "CSV"
  }
}

# Folder next to the approved folder: 1 finding
resource "google_bigquery_data_transfer_config" "sibling_folder" {
  project                = "my-project"
  display_name           = "sibling-folder"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    data_path_template              = "gs://trusted-corp-archive/inbound-old/*.csv"
    destination_table_name_template = "orders"
    file_format                     = "CSV"
  }
}

# delete_source_files written as a boolean: 1 finding
resource "google_bigquery_data_transfer_config" "deletes_unquoted" {
  project                = "my-project"
  display_name           = "deletes-unquoted"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    data_path_template              = "gs://trusted-corp-landing/incoming/*.csv"
    destination_table_name_template = "orders"
    file_format                     = "CSV"
    delete_source_files             = true
  }
}

# Dataset ID that only contains an approved ID: 1 finding
resource "google_bigquery_data_transfer_config" "lookalike_destination" {
  project                = "my-project"
  display_name           = "lookalike-destination"
  data_source_id         = "scheduled_query"
  destination_dataset_id = "raw_ingestion_zone_shadow"
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    query = "SELECT 1"
  }
}

# Approved dataset ID in a project that is not approved: 1 finding
resource "google_bigquery_data_transfer_config" "other_project" {
  project                = "my-project-rogue"
  display_name           = "other-project"
  data_source_id         = "scheduled_query"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    query = "SELECT 1"
  }
}

# No project in the resource, so the destination cannot be matched: 1 finding
resource "google_bigquery_data_transfer_config" "no_project" {
  display_name           = "no-project"
  data_source_id         = "scheduled_query"
  destination_dataset_id = "raw_ingestion_zone"
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    query = "SELECT 1"
  }
}

# The dataset resource is named like an approved ID but its dataset_id is
# not approved: 1 finding
resource "google_bigquery_dataset" "raw_ingestion_zone" {
  project    = "my-project"
  dataset_id = "shadow_zone"
  location   = "US"
}

resource "google_bigquery_data_transfer_config" "reference_to_shadow" {
  project                = "my-project"
  display_name           = "reference-to-shadow"
  data_source_id         = "scheduled_query"
  destination_dataset_id = google_bigquery_dataset.raw_ingestion_zone.dataset_id
  location               = "us"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"

  params = {
    query = "SELECT 1"
  }
}

# Bigquery.C19 (bigquery_authorized_configuration) - universal - COMPLIANT

resource "google_bigquery_dataset" "baseline" {
  dataset_id                  = "baseline_data"
  location                    = "US"
  default_table_expiration_ms = 2592000000
  max_time_travel_hours       = 168
}

# External dataset: its tables live in the external source and cannot expire,
# so the dataset is out of scope
resource "google_bigquery_dataset" "federated" {
  dataset_id = "federated_data"
  location   = "US"

  external_dataset_reference {
    external_source = "aws-glue://arn:aws:glue:us-east-1:111122223333:database/sales"
    connection      = "projects/example-project/locations/aws-us-east-1/connections/glue"
  }
}

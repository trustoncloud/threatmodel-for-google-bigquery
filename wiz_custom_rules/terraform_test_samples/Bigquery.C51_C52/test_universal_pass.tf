# Bigquery.C52 (bigquery_time_travel) - universal - COMPLIANT

resource "google_bigquery_dataset" "standard_travel" {
  dataset_id            = "standard_travel_data"
  location              = "US"
  max_time_travel_hours = 168
}

# Attribute omitted: GCP applies the 168h default
resource "google_bigquery_dataset" "default_travel" {
  dataset_id = "default_travel_data"
  location   = "US"
}

# External dataset: it has no time travel window, so it is out of scope
resource "google_bigquery_dataset" "federated" {
  dataset_id = "federated_data"
  location   = "US"

  external_dataset_reference {
    external_source = "aws-glue://arn:aws:glue:us-east-1:111122223333:database/sales"
    connection      = "projects/example-project/locations/aws-us-east-1/connections/glue"
  }
}

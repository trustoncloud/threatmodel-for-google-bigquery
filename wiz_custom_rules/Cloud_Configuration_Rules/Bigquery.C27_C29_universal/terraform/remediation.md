Give every dataset a default Cloud KMS key. A table uses its own key, or inherits its dataset's default:

```hcl
resource "google_bigquery_dataset" "example" {
  dataset_id = "example_dataset"

  default_encryption_configuration {
    kms_key_name = "projects/example-project/locations/us/keyRings/example-ring/cryptoKeys/example-key"
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = "example_table"

  encryption_configuration {
    kms_key_name = "projects/example-project/locations/us/keyRings/example-ring/cryptoKeys/example-key"
  }
}
```

A transfer from a data source in `cmek_capable_transfer_sources` names a key too. BigQuery takes a key only on a transfer created with one, so recreate a transfer that has none with the key (for example with `terraform apply -replace`):

```hcl
resource "google_bigquery_data_transfer_config" "example" {
  display_name           = "example-load"
  location               = "US"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = google_bigquery_dataset.example.dataset_id

  params                 = var.load_params

  encryption_configuration {
    kms_key_name = "projects/example-project/locations/us/keyRings/example-ring/cryptoKeys/example-key"
  }
}
```

A transfer from any other source is skipped, because it takes no key. Add a source to that list only when its BigQuery Data Transfer Service page documents a customer-managed key for it. A source taken from a variable or another resource is not known until apply, so that transfer must name a key.

BigQuery's service account needs the Cloud KMS CryptoKey Encrypter/Decrypter role on each key.

Two limits of a source scan:

- A table without `encryption_configuration` passes only when its dataset is declared in the same scan with a default key. The table belongs to that dataset when its `dataset_id` is the dataset's ID or a reference to it (`google_bigquery_dataset.<name>.dataset_id`), and both set the same `project`, or both leave it out and use the same provider configuration (the same `provider` alias; leaving `provider` out is the same as `provider = google`). A scan can hold files from several modules, each with its own default project, so this applies only when the two sit in the same file or the reference names a dataset resource that only one dataset in the scan has. In any other case both must set `project` to the same literal value. Otherwise give the table its own key.
- A dataset default applies only to tables created afterward. A table that already exists keeps the key it was created with, which the source does not show.

A dataset with an `external_dataset_reference` block is skipped. Its data stays in the external source, so it has no default key to set.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)
- [google_bigquery_data_transfer_config (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_data_transfer_config)

Checked 2026-11-18 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

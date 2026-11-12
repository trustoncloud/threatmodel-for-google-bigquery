Give every dataset a default key from `authorized_kms_keys`, and give a table its own approved key or leave it to inherit its dataset's default. Once a key is approved, add its full name to `authorized_kms_keys` in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  dataset_id = "example_dataset"

  default_encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key"
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = "example_table"

  encryption_configuration {
    kms_key_name = "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key"
  }
}
```

A key matches an entry only when project, location, key ring and key are all the same. List each key without a version: BigQuery names a key, never a key version, so an entry ending in `/cryptoKeyVersions/<n>` matches nothing.

Three limits of a source scan:

- A table without `encryption_configuration` passes only when its dataset is declared in the same scan with an approved default key. The table belongs to that dataset when its `dataset_id` is the dataset's ID or a reference to it (`google_bigquery_dataset.<name>.dataset_id`), and both set the same `project`, or both leave it out and use the same provider configuration (the same `provider` alias; leaving `provider` out is the same as `provider = google`). A scan can hold files from several modules, each with its own default project, so this applies only when the two sit in the same file or the reference names a dataset resource that only one dataset in the scan has. In any other case both must set `project` to the same literal value. Otherwise give the table its own key.
- A key set from a variable or another resource is not known until apply, so it is reported. Write the key name in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- A dataset default applies only to tables created afterward. A table that already exists keeps the key it was created with, which the source does not show.

A dataset with an `external_dataset_reference` block is skipped. Its data stays in the external source, so it has no default key to set.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

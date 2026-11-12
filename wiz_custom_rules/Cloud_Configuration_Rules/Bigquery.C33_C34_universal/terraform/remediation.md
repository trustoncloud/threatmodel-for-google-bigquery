Set `expiration_time`, in milliseconds since the epoch, on the table (here, January 1, 2027 UTC), or give its dataset a `default_table_expiration_ms`:

```hcl
resource "google_bigquery_table" "example" {
  expiration_time = 1798761600000
}
```

```hcl
resource "google_bigquery_dataset" "example" {
  default_table_expiration_ms = 2592000000
}
```

Three limits of a source scan:

- A table without `expiration_time` passes only when its dataset is declared in the same scan with a `default_table_expiration_ms` written as a number. The table belongs to that dataset when its `dataset_id` is the dataset's ID or a reference to it (`google_bigquery_dataset.<name>.dataset_id`), and both set the same `project`, or both leave it out and use the same provider configuration (the same `provider` alias; leaving `provider` out is the same as `provider = google`). A scan can hold files from several modules, each with its own default project, so this applies only when the two sit in the same file or the reference names a dataset resource that only one dataset in the scan has. In any other case both must set `project` to the same literal value. Otherwise give the table its own `expiration_time`.
- A default set from a variable or another resource is not known until apply, so the table is reported. Write the number in the dataset. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- A dataset default applies only to tables created afterward. A table that already exists keeps the expiration it was created with, which the source does not show.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

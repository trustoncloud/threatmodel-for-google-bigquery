Declare the dataset in a location from `authorized_locations`, with expirations in milliseconds from `authorized_table_expirations_ms` and `authorized_partition_expirations_ms`, or add an approved value to those constants in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  location                        = "US"
  default_table_expiration_ms     = 2592000000
  default_partition_expiration_ms = 5184000000
}
```

A dataset without `location` is created in the `US` multi-region, so declare it explicitly when `US` is not authorized. Location names are matched regardless of case. Changing `location` makes Terraform replace the dataset, so move its data first.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

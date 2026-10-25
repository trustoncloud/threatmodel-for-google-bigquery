Set `require_partition_filter` on every table that declares `time_partitioning` or `range_partitioning`:

```hcl
resource "google_bigquery_table" "example" {
  require_partition_filter = true

  time_partitioning {
    type = "DAY"
  }
}
```

The same flag inside `time_partitioning` also passes, but the provider deprecates it in favor of the top-level argument. Hive-partitioned external tables are not judged.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

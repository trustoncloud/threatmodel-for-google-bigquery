Set a `metadata_cache_mode` listed in `authorized_metadata_cache_modes`, and a `max_staleness` inside the authorized window, written as an interval `Y-M D H:M:S` with a zero year-month part:

```hcl
resource "google_bigquery_table" "example" {
  max_staleness = "0-0 0 4:0:0"

  external_data_configuration {
    metadata_cache_mode = "AUTOMATIC"
  }
}
```

The matcher reads only the days, hours, minutes and seconds of `max_staleness`, so it does not count a year-month part.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Set `expiration_time`, in milliseconds since the epoch, on every table (here, January 1, 2027 UTC):

```hcl
resource "google_bigquery_table" "example" {
  expiration_time = 1798761600000
}
```

The matcher reads only the table, so a dataset's default table expiration does not satisfy it.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

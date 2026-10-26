Use a `write_disposition` listed in `authorized_write_dispositions` (`WRITE_APPEND`, or `WRITE_EMPTY`, the default) and set no `schema_update_options`:

```hcl
resource "google_bigquery_job" "example" {
  query {
    write_disposition = "WRITE_APPEND"
  }
}
```

If overwrites or schema updates are approved, add the write mode to `authorized_write_dispositions` or set `allow_schema_updates` to `true` in the rule's configuration instead. A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

## References

- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

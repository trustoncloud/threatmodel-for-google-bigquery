Use a `write_disposition` listed in `authorized_write_dispositions` (`WRITE_APPEND`, or `WRITE_EMPTY`, the default) and set no `schema_update_options`:

```hcl
resource "google_bigquery_job" "example" {
  query {
    write_disposition = "WRITE_APPEND"
  }
}
```

A job that writes to a `destination_table` must also use a `create_disposition` listed in `authorized_create_dispositions`. Both `CREATE_IF_NEEDED` (the default) and `CREATE_NEVER` are listed to begin with; remove `CREATE_IF_NEEDED` from the list to require that the destination table already exists.

If overwrites or schema updates are approved, add the write mode to `authorized_write_dispositions` or set `allow_schema_updates` to `true` in the rule's configuration instead. A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

A write or create mode set from a variable or another resource is not known until apply, so it is reported. Write the mode in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

What the rule cannot show: it reads `write_disposition`, `create_disposition` and `schema_update_options` and does not read the query text. A job whose `query` runs `DROP`, `DELETE`, `TRUNCATE` or another statement that removes data passes when its write mode is approved, so review the text of declared queries.

## References

- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

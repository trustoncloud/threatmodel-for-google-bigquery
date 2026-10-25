Set `maximum_bytes_billed` on every query job, and leave `ignore_unknown_values` unset or `false` on every load job:

```hcl
resource "google_bigquery_job" "query" {
  query {
    maximum_bytes_billed = "10000000000"
  }
}

resource "google_bigquery_job" "load" {
  load {
    ignore_unknown_values = false
  }
}
```

A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

## References

- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

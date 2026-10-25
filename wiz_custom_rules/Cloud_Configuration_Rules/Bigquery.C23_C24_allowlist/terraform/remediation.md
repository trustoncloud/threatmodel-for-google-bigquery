Point external tables, load jobs and extract jobs at URIs that start with a prefix listed in `authorized_uri_prefixes`, or, once a location is approved, add its prefix to `authorized_uri_prefixes` in the rule's configuration:

```hcl
resource "google_bigquery_table" "example" {
  external_data_configuration {
    source_uris = ["gs://<authorized-bucket>/<path>"]
  }
}

resource "google_bigquery_job" "load" {
  load {
    source_uris = ["gs://<authorized-bucket>/<path>"]
  }
}

resource "google_bigquery_job" "extract" {
  extract {
    destination_uris = ["gs://<authorized-bucket>/<path>"]
  }
}
```

A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)
- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Load UDF code only from a prefix listed in `authorized_udf_uri_prefixes`, or, once the bucket is approved, add its prefix to `authorized_udf_uri_prefixes` in the rule's configuration:

```hcl
resource "google_bigquery_job" "example" {
  query {
    user_defined_function_resources {
      resource_uri = "gs://<trusted-bucket>/<file>"
    }
  }
}
```

A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

## References

- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

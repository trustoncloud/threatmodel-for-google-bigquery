Load UDF code only from a location listed in `authorized_udf_locations`, or, once the bucket is approved, add it to `authorized_udf_locations` in the rule's configuration:

```hcl
resource "google_bigquery_job" "example" {
  query {
    user_defined_function_resources {
      resource_uri = "gs://<trusted-bucket>/<file>"
    }
  }
}
```

`gs://<bucket>` trusts the whole bucket and `gs://<bucket>/<folder>/` only what is inside that folder; a bucket with a longer name or a folder next to the trusted one is reported. A location set from a variable or another resource is not known until apply, so it is reported: write the URI in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

## References

- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

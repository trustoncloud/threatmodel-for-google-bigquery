Declare no BigQuery Omni connections (a `google_bigquery_connection` with an `aws` or `azure` block), and keep both Omni constraints enforced wherever Terraform declares them:

```hcl
resource "google_org_policy_policy" "disable_bq_omni_aws" {
  name   = "organizations/<organization-id>/policies/bigquery.disableBQOmniAWS"
  parent = "organizations/<organization-id>"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
```

Declare the same for `bigquery.disableBQOmniAzure`; with the legacy resources, set `boolean_policy { enforced = true }`. A ban that Terraform does not declare is not reported, since it may be set elsewhere.

## References

- [google_org_policy_policy (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/org_policy_policy)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

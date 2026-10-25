Turn on restricted export, including query results, on every listing:

```hcl
resource "google_bigquery_analytics_hub_listing" "example" {
  restricted_export_config {
    enabled               = true
    restrict_query_result = true
  }
}
```

Leave out `discovery_type`, which cannot be set on a restricted listing.

## References

- [google_bigquery_analytics_hub_listing (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

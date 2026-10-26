Give every listing restricted export, a description and documentation, or, if the listing is approved to allow export, add its `listing_id` to `authorized_exportable_listing_ids` in the rule's configuration:

```hcl
resource "google_bigquery_analytics_hub_listing" "example" {
  listing_id    = "regional_sales"
  description   = "Daily sales totals by region."
  documentation = "Columns, refresh schedule and support channel for this listing."

  restricted_export_config {
    enabled = true
  }
}
```

Do not set `discovery_type` to `DISCOVERY_TYPE_PUBLIC`. On a restricted listing, leave `discovery_type` out, since it cannot be set there.

## References

- [google_bigquery_analytics_hub_listing (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

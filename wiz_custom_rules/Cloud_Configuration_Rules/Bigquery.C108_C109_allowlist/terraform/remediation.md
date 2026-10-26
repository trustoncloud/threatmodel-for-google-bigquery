Subscribe only to listings in an authorized data exchange: set `data_exchange_id` to an exchange listed in `authorized_source_exchange_ids` in the rule's configuration, or add the exchange ID there once approved.

```hcl
resource "google_bigquery_analytics_hub_listing_subscription" "example" {
  data_exchange_id = "governed_partner_exchange"
}
```

The matcher compares the exchange ID only, so an exchange with the same ID in another project also passes.

## References

- [google_bigquery_analytics_hub_listing_subscription (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing_subscription)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

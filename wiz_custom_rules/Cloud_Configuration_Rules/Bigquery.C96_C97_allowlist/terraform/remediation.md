Set `discovery_type` to private on every data exchange, or, if publishing the exchange is approved, add its `data_exchange_id` to `authorized_public_exchange_ids` in the rule's configuration:

```hcl
resource "google_bigquery_analytics_hub_data_exchange" "example" {
  data_exchange_id = "partner_exchange"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}
```

The matcher treats a missing `discovery_type` as private, but the provider then keeps whatever value the live exchange has, so set it explicitly on every exchange except a data clean room, which does not accept it.

## References

- [google_bigquery_analytics_hub_data_exchange (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_data_exchange)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

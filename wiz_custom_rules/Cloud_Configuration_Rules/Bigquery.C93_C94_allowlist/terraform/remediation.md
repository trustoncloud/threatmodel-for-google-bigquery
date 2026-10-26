Declare each exchange whose `data_exchange_id` is listed in `required_dcr_exchange_ids` in the rule's configuration as a data clean room, or remove the ID from that list if the exchange is no longer required to be one:

```hcl
resource "google_bigquery_analytics_hub_data_exchange" "example" {
  data_exchange_id = "sensitive_partner_exchange"

  sharing_environment_config {
    dcr_exchange_config {}
  }
}
```

The provider replaces an existing exchange when `sharing_environment_config` changes, which deletes its listings, so plan the move of the shared data first. Leave out `discovery_type`, which cannot be set on a data clean room.

## References

- [google_bigquery_analytics_hub_data_exchange (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_data_exchange)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

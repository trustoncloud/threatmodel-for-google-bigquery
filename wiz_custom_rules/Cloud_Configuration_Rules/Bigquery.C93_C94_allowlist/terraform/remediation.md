Declare each exchange listed in `required_dcr_exchange_names_by_project_id` in the rule's configuration as a data clean room, or remove its name from that list if the exchange is no longer required to be one:

```hcl
resource "google_bigquery_analytics_hub_data_exchange" "example" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "sensitive_partner_exchange"

  sharing_environment_config {
    dcr_exchange_config {}
  }
}
```

A required exchange is matched on its project, location and ID together, as `projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>`. Terraform names the project by its ID, so write the project ID in the configuration (the cloud rule's list uses the project number for the same exchange). The provider's default project and values taken from a variable or another resource are not in the source. An exchange that leaves `project`, `location` or `data_exchange_id` to one of them is matched on the parts it does state, so it is reported when those parts match a required exchange: write all three in the resource to have it matched in full. A variable that declares a default is checked at that default, because the scan reads the Terraform source. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

The provider replaces an existing exchange when `sharing_environment_config` changes, which deletes its listings, so plan the move of the shared data first. Leave out `discovery_type`, which cannot be set on a data clean room.

## References

- [google_bigquery_analytics_hub_data_exchange (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_data_exchange)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

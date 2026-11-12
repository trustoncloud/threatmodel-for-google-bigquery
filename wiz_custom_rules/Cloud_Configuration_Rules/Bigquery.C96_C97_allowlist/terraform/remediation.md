Set `discovery_type` to private on every data exchange, or, if publishing the exchange is approved, add its full name, `projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>`, to `authorized_public_exchange_names_by_project_id` in the rule's configuration:

```hcl
resource "google_bigquery_analytics_hub_data_exchange" "example" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "partner_exchange"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}
```

An approved exchange is matched on its project, location and ID together, so the same ID in another project or location is reported. Terraform names the project by its ID, so write the project ID in the configuration (the cloud rule's list uses the project number for the same exchange). A published exchange must state `project`, `location` and `data_exchange_id` as literal values: the provider's default project and values taken from a variable or another resource are not in the source, so an exchange that relies on them cannot be matched and is reported. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

The matcher treats a missing `discovery_type` as private, but the provider then keeps whatever value the live exchange has, so set it explicitly on every exchange except a data clean room, which does not accept it.

## References

- [google_bigquery_analytics_hub_data_exchange (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_data_exchange)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

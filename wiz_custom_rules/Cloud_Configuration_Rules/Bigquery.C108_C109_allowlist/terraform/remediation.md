Subscribe only to an approved listing, from an approved project. Point the subscription at an exchange listed in `authorized_source_exchange_names_by_project_id` or a listing listed in `authorized_source_listing_names_by_project_id` in the rule's configuration, and create the linked dataset in a project listed in `authorized_subscriber_project_ids`, or add the name there once approved:

```hcl
resource "google_bigquery_analytics_hub_listing_subscription" "example" {
  project          = "partner-project"
  location         = "us"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"

  destination_dataset {
    location = "us"

    dataset_reference {
      project_id = "my-project"
      dataset_id = "linked_partner_sales"
    }
  }
}
```

- The listing is matched on its project, location, exchange and listing together. An exchange entry is written `projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>` and approves every listing in that exchange. A listing entry adds `/listings/<listing-id>` and approves that listing only. The same exchange ID in another project or location is reported.
- `project` and `location` on the resource name the publisher's listing, and Terraform names the project by its ID, so write the publisher's project ID in the configuration.
- The provider's default project and values taken from a variable or another resource are not in the source, so a subscription that leaves `project`, `location` or `data_exchange_id` to one of them is reported. A `listing_id` that is not a literal value passes only in an exchange approved as a whole. A destination `project_id` that is not a literal value is reported. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

## References

- [google_bigquery_analytics_hub_listing_subscription (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing_subscription)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

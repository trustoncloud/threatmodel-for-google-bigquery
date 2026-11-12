Give every listing a description and documentation, and restricted export when it shares a BigQuery dataset, or, if the listing is approved to allow export, add its `listing_id` to `authorized_exportable_listing_ids` in the rule's configuration:

```hcl
resource "google_bigquery_analytics_hub_data_exchange" "example" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "internal_catalog"
  display_name     = "Internal Catalog"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}

resource "google_bigquery_analytics_hub_listing" "example" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.example.data_exchange_id
  listing_id       = "regional_sales"
  display_name     = "Regional Sales"
  description      = "Daily sales totals by region."
  documentation    = "Columns, refresh schedule and support channel for this listing."

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/my-project/datasets/regional_sales"
  }
}
```

Do not set `discovery_type` to `DISCOVERY_TYPE_PUBLIC`. On a restricted listing, leave `discovery_type` out, since it cannot be set there.

- A listing that leaves out `discovery_type` takes the one of its data exchange, so it is reported when that exchange sets `DISCOVERY_TYPE_PUBLIC`. Keep the exchange private. A restricted listing always takes it from its exchange, since it cannot set its own.
- The exchange of a listing is the one with the same ID, project and location. `data_exchange_id` gives the ID, written in the listing or read through a reference (`google_bigquery_analytics_hub_data_exchange.<name>.data_exchange_id`). A reference gives the ID only: the listing's own `project` and `location` decide which exchange it is. The project agrees when both resources state the same one, or both leave it to the same provider configuration. The exchange is looked for in the same file first, then as the only match in the scan. A reference that cannot be resolved, an exchange whose project or location cannot be compared with the listing's, or an ID that two other files declare, is reported.
- An exchange that no file in the scan declares cannot be read. Declare the private exchange in the scanned files, or, when it is managed elsewhere and private, add it to `authorized_private_exchange_names_by_project_id` in the rule's configuration as `projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>`. A listing under an exchange that is in neither place is reported, and so is one that states no literal `project` and `location` to match the list with. IAM grants on the exchange are not read.
- A `discovery_type` set from a variable or another resource is not known until apply, so it is reported, on the listing or on its exchange. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- A listing that shares only a Pub/Sub topic (`pubsub_topic` and no `bigquery_dataset`) is not checked for restricted export, which applies to a shared dataset.

## References

- [google_bigquery_analytics_hub_data_exchange (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_data_exchange)
- [google_bigquery_analytics_hub_listing (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

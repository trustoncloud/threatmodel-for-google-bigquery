Declare transfers with an authorized `data_source_id`, `destination_dataset_id` and `service_account_name`, and, for Cloud Storage, a `data_path_template` under a trusted prefix with `delete_source_files` off. Once a value is approved, add it to the matching list in the rule's configuration:

```hcl
resource "google_bigquery_data_transfer_config" "example" {
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"
  params                 = { data_path_template = "gs://trusted-corp-landing/*.csv", delete_source_files = "false" }
}
```

A transfer that leaves out `service_account_name` runs as the identity that applies it, which the plan does not show; the rule's cloud check judges that identity once the transfer exists.

## References

- [google_bigquery_data_transfer_config (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_data_transfer_config)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

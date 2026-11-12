Declare transfers with an approved `data_source_id`, an approved destination (`project` and `destination_dataset_id` together) and an approved `service_account_name`, and, for Cloud Storage, a `data_path_template` in an approved bucket or folder with `delete_source_files` off. Once a value is approved, add it to the matching list in the rule's configuration:

```hcl
resource "google_bigquery_data_transfer_config" "example" {
  project                = "my-project"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = "raw_ingestion_zone"
  service_account_name   = "etl-loader@my-project.iam.gserviceaccount.com"
  params                 = { data_path_template = "gs://trusted-corp-landing/*.csv", delete_source_files = "false" }
}
```

- **Destination.** `authorized_destination_datasets_by_project_id` lists `projects/<project-id>/datasets/<dataset>`. The same dataset ID in another project is a different destination, so the resource must set `project` to a literal value. A transfer that leaves `project` to the provider, or takes it from a variable, is reported, because the source does not show which project it writes to. `destination_dataset_id` can be a literal ID or a reference to a `google_bigquery_dataset` in the same scan (`google_bigquery_dataset.<name>.dataset_id`), which is read from that dataset's own `dataset_id`. The reference is resolved to the dataset resource in the same file, or, when that file declares none, to the only dataset resource with that name in the scan. If two other files declare the name, or that dataset's own `dataset_id` comes from a variable with no default, the dataset is not known. A destination that is not known is reported.
- **Cloud Storage.** In `authorized_gcs_paths`, `gs://<bucket>` approves everything in that bucket and `gs://<bucket>/<folder>/` only what is inside that folder. Bucket names match exactly. `delete_source_files` is reported as `true` or `"true"`.
- **Run identity.** A transfer that leaves out `service_account_name` runs as the identity that applies it, which the source does not show; the rule's cloud check judges that identity once the transfer exists. A `service_account_name` taken from a variable or another resource is not known until apply, so it is reported: write the address in the resource.
- **Variables.** A variable that declares a default is checked at that default, because the scan reads the Terraform source. Terraform can deploy a value passed in its place, and a passing scan does not cover that value. This holds for `project`, the destination dataset and `service_account_name` alike.
- **Scheduled queries.** The rule does not read the SQL in `params.query`. A query can read other tables, change data or export results with `EXPORT DATA` whatever its destination dataset is, so review the query itself.

## References

- [google_bigquery_data_transfer_config (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_data_transfer_config)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

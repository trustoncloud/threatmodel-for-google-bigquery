# Remediation

The transfer configuration in the finding is not approved for one of these reasons:

- Its data source is not in `authorized_data_source_ids`.
- Its destination, the project and dataset together, is not in `authorized_destination_datasets`.
- Its run identity is not in `authorized_transfer_identities`, or no run identity is reported, so nobody can confirm who it runs as.
- It is a Cloud Storage transfer that reads outside `authorized_gcs_paths` or deletes its source files.

Correct or delete the transfer, or, once the value is approved, add it to that list in the rule's configuration. Write a destination as `projects/<project-number>/datasets/<dataset>`: a transfer writes to a dataset in its own project, and the same dataset ID in another project is a different destination. In `authorized_gcs_paths`, `gs://<bucket>` approves everything in that bucket and `gs://<bucket>/<folder>/` only what is inside that folder. Bucket names match exactly, so an approved bucket does not approve a bucket whose name starts the same way.

1. Show the transfer's current settings:

   ```bash
   bq show --format=prettyjson --transfer_config <transfer-config>
   ```

2. Point it at an authorized dataset:

   ```bash
   bq update --transfer_config --target_dataset=<dataset> <transfer-config>
   ```

   For a Cloud Storage transfer, also set its parameters: pass the full `params` from step 1, with `data_path_template` in an approved bucket or folder and `delete_source_files` set to `"false"`:

   ```bash
   bq update --transfer_config --params='<params-json>' <transfer-config>
   ```

3. Run it as an authorized service account. This also fixes a transfer with no run identity reported:

   ```bash
   bq update --transfer_config --service_account_name=<service-account-email> <transfer-config>
   ```

4. A transfer's data source cannot be changed. Delete a transfer that uses an unauthorized source, and create a new one from an authorized source if it is still needed:

   ```bash
   bq rm --transfer_config <transfer-config>
   ```

Replace `<transfer-config>` with the transfer configuration's resource name in the finding, `<dataset>` and `<service-account-email>` with an authorized dataset and identity, and `<params-json>` with the edited parameters. The rule does not read the SQL of a scheduled query. A query can read other tables, change data or export results with `EXPORT DATA` whatever its destination dataset is, so review the `query` parameter that step 1 shows, and limit what the run identity can reach.

## References

- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [Manage transfers](https://docs.cloud.google.com/bigquery/docs/working-with-transfers)
- [Load Cloud Storage data into BigQuery](https://docs.cloud.google.com/bigquery/docs/cloud-storage-transfer)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
For a transfer, 1) use an unauthorized source, 2) remove an authorized source, or 3) use an unauthorized configuration for a source; it should be detected.

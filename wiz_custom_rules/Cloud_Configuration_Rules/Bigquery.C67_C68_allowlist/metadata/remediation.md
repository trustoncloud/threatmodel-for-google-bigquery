# Remediation

The transfer configuration in the finding is not authorized: its data source, destination dataset or run identity is outside the authorized lists, or, for a Cloud Storage transfer, it reads outside the trusted path prefixes or deletes its source files. Correct or delete the transfer, or, once the value is approved, add it to `authorized_data_source_ids`, `authorized_destination_datasets`, `authorized_transfer_identities` or `authorized_gcs_path_prefixes` in the rule's configuration.

1. Show the transfer's current settings:

   ```bash
   bq show --format=prettyjson --transfer_config <transfer-config>
   ```

2. Point it at an authorized dataset:

   ```bash
   bq update --transfer_config --target_dataset=<dataset> <transfer-config>
   ```

   For a Cloud Storage transfer, also set its parameters: pass the full `params` from step 1, with `data_path_template` under a trusted prefix and `delete_source_files` set to `"false"`:

   ```bash
   bq update --transfer_config --params='<params-json>' <transfer-config>
   ```

3. Run it as an authorized service account:

   ```bash
   bq update --transfer_config --service_account_name=<service-account-email> <transfer-config>
   ```

4. A transfer's data source cannot be changed. Delete a transfer that uses an unauthorized source, and create a new one from an authorized source if it is still needed:

   ```bash
   bq rm --transfer_config <transfer-config>
   ```

Replace `<transfer-config>` with the transfer configuration's resource name in the finding, `<dataset>` and `<service-account-email>` with an authorized dataset and identity, and `<params-json>` with the edited parameters. A transfer whose owner the API does not report is not judged on its run identity.

## References

- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [Manage transfers](https://docs.cloud.google.com/bigquery/docs/working-with-transfers)
- [Load Cloud Storage data into BigQuery](https://docs.cloud.google.com/bigquery/docs/cloud-storage-transfer)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
For a transfer, 1) use an unauthorized source, 2) remove an authorized source, or 3) use an unauthorized configuration for a source; it should be detected.

# Remediation

An external table or a declared job in the finding reads data from, or writes data to, a location outside the authorized list. Move the data flow to an authorized location, or, once the location is approved, add its URI prefix to `authorized_uri_prefixes` in the rule's configuration.

1. External table: redefine it on an authorized source. Restate its column list, `WITH CONNECTION` clause and other options as they are now, and change only `uris`:

   ```sql
   CREATE OR REPLACE EXTERNAL TABLE `<project-id>.<dataset>.<table>`
   OPTIONS (
     format = '<format>',
     uris = ['gs://<authorized-bucket>/<path>']
   );
   ```

   Run it in the BigQuery console or with `bq query --nouse_legacy_sql`. If the table is no longer needed, delete it instead with `bq rm -t <project-id>:<dataset>.<table>`.

2. Load or extract job: a job cannot be changed once it has run. Cancel it if it is still running, and run future loads and extracts against authorized locations only:

   ```bash
   bq cancel <project-id>:<location>.<job-id>
   ```

3. If an extract job already wrote files to an unauthorized bucket that you control, delete them:

   ```bash
   gcloud storage rm gs://<bucket>/<object>
   ```

Only tables and jobs declared in Terraform are checked; tables and jobs created with `bq`, the console or the API are not. Replace `<project-id>`, `<dataset>`, `<table>`, `<location>` and `<job-id>` with the resource the finding names, `<format>` with the table's current format, `<authorized-bucket>` and `<path>` with the new source, and `<bucket>` and `<object>` with the files the extract wrote.

## References

- [gcloud storage rm](https://docs.cloud.google.com/sdk/gcloud/reference/storage/rm)
- [bq cancel](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cancel)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [Introduction to external tables](https://docs.cloud.google.com/bigquery/docs/external-tables)
- [Create Cloud Storage BigLake tables](https://docs.cloud.google.com/bigquery/docs/create-cloud-storage-table-biglake)
- [Manage jobs](https://docs.cloud.google.com/bigquery/docs/managing-jobs)
- [Export table data to Cloud Storage](https://docs.cloud.google.com/bigquery/docs/exporting-data)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
For a BigQuery dataset, table, model, connection, job, or listing, use an unauthorized 1) source or 2) destination; it should be detected.

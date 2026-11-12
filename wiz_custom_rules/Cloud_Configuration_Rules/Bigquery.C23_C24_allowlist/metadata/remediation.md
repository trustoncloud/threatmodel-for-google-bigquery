# Remediation

An external table or a declared job in the finding reads data from, or writes data to, a location that is not approved. Move the data flow to an approved location, or, once the location is approved, add it to the rule's configuration: a Cloud Storage source to `authorized_source_gcs`, a Cloud Storage export destination to `authorized_destination_gcs`, and the host of a source outside Cloud Storage, such as Google Drive, to `authorized_source_hosts`. Sources and destinations are separate lists, so a bucket approved for reading is not approved for exports until it is in both. `gs://<bucket>` approves the whole bucket and `gs://<bucket>/<folder>/` only what is inside that folder; a bucket with a longer name or a folder next to the approved one is reported.

A declared job is also reported when it reads or writes a BigQuery table that is not approved. Add a table a job may read to `authorized_source_tables_by_project_id` and a table a job may write to `authorized_destination_tables_by_project_id`, as `projects/<project-id>/datasets/<dataset>/tables/<table>` with the project ID. An entry that stops at the dataset approves every table and model in it.

1. External table: redefine it on an approved source. Restate its column list, `WITH CONNECTION` clause and other options as they are now, and change only `uris`:

   ```sql
   CREATE OR REPLACE EXTERNAL TABLE `<project-id>.<dataset>.<table>`
   OPTIONS (
     format = '<format>',
     uris = ['gs://<approved-bucket>/<path>']
   );
   ```

   Run it in the BigQuery console or with `bq query --nouse_legacy_sql`. If the table is no longer needed, delete it instead with `bq rm -t <project-id>:<dataset>.<table>`.

2. Load, extract, copy or query job: a job cannot be changed once it has run. Cancel it if it is still running, and run future jobs against approved locations and tables only:

   ```bash
   bq cancel <project-id>:<location>.<job-id>
   ```

3. If an extract job already wrote files to a bucket that is not approved and that you control, delete them:

   ```bash
   gcloud storage rm gs://<bucket>/<object>
   ```

Replace `<project-id>`, `<dataset>`, `<table>`, `<location>` and `<job-id>` with the resource the finding names, `<format>` with the table's current format, `<approved-bucket>` and `<path>` with the new source, and `<bucket>` and `<object>` with the files the extract wrote.

What the rule does not check:

- Tables and jobs created with `bq`, the console or the API. Only tables and jobs declared in Terraform are read.
- The tables a query job selects from. The SQL is not read; only the job's destination table is compared.
- Datasets, models, connections and Analytics Hub listings. The rule covers external table sources and the Cloud Storage and table endpoints of load, extract, copy and query jobs.

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

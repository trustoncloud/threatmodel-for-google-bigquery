# Remediation

A declared query job overwrites its destination table (`WRITE_TRUNCATE`), changes the table's schema through schema update options, or uses a create mode for its destination table that is not in `authorized_create_dispositions`. A job cannot be changed once it has run: cancel it if it is still running, recover what it overwrote, and run future queries without overwrites or schema updates.

1. Cancel the job if it is still running:

   ```bash
   bq cancel <project-id>:<location>.<job-id>
   ```

2. If the job already overwrote a table, copy the table as it was before the job into a new table, while that time is still inside the time travel window:

   ```bash
   bq cp <project-id>:<dataset>.<table>@<epoch-ms> <project-id>:<dataset>.<restored-table>
   ```

3. Run future queries that append (`--append_table`) or write only to an empty table (the default), and pass neither `--replace` nor `--schema_update_option`:

   ```bash
   bq query --nouse_legacy_sql --append_table \
     --destination_table=<project-id>:<dataset>.<table> '<query>'
   ```

If overwrites or schema updates are approved, add the write mode to `authorized_write_dispositions` or set `allow_schema_updates` to `true` in the rule's configuration instead. `authorized_create_dispositions` lists both create modes to begin with; remove `CREATE_IF_NEEDED` from it to require that a job's destination table already exists. Replace `<project-id>`, `<dataset>`, `<table>`, `<location>` and `<job-id>` with the job and destination table the finding names, `<epoch-ms>` with a time before the job ran, in milliseconds since the epoch, `<restored-table>` with a new table name, and `<query>` with the query text.

What the rule cannot show:

- The rule reads the job's write mode, create mode and schema update options. It does not read the query text, so a job whose query runs `DROP`, `DELETE`, `TRUNCATE` or another statement that removes data passes when its write mode is approved. Review the text of declared queries, and limit who can run such statements with IAM.
- Only jobs declared in Terraform are checked. Queries run outside Terraform are not.

## References

- [bq cancel](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cancel)
- [bq cp](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cp)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Manage jobs](https://docs.cloud.google.com/bigquery/docs/managing-jobs)
- [Access historical data](https://docs.cloud.google.com/bigquery/docs/access-historical-data)
- [Write query results](https://docs.cloud.google.com/bigquery/docs/writing-results)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Create an asynchronous query job with unauthorized configurations; it should be detected.

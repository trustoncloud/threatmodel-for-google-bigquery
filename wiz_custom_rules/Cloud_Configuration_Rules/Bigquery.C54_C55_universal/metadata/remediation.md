# Remediation

A declared job in the finding breaks a job safety baseline: a query job sets no `maximum_bytes_billed` limit, or a load job sets `ignore_unknown_values` and so ignores values that the table schema does not hold. A job cannot be changed once it has run, so cancel it if it is still running and run future jobs with safe settings.

1. Cancel the job if it is still running:

   ```bash
   bq cancel <project-id>:<location>.<job-id>
   ```

2. Run queries with a byte limit, so a query that would bill more fails without a charge:

   ```bash
   bq query --nouse_legacy_sql --maximum_bytes_billed=<max-bytes> '<query>'
   ```

3. Run loads without `--ignore_unknown_values`, so values outside the schema count as bad records and the load fails once there are too many.

Only jobs declared in Terraform are checked; jobs run with `bq`, the console, client libraries or the API are not. Replace `<project-id>`, `<location>` and `<job-id>` with the job the finding names, `<max-bytes>` with the most bytes a query may bill, and `<query>` with the query text.

## References

- [bq cancel](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cancel)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Manage jobs](https://docs.cloud.google.com/bigquery/docs/managing-jobs)
- [Estimate and control costs](https://docs.cloud.google.com/bigquery/docs/best-practices-costs)
- [Load CSV data from Cloud Storage](https://docs.cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Use an unauthorized configuration with a job; it should be detected.

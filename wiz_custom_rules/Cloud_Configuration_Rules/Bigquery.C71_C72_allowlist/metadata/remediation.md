# Remediation

A declared query job loads user-defined function (UDF) code from a Cloud Storage location that is not trusted. Load UDF code only from a trusted bucket, or, once the bucket is approved, add its URI prefix to `authorized_udf_uri_prefixes` in the rule's configuration.

1. A job cannot be changed once it has run. Cancel it if it is still running:

   ```bash
   bq cancel <project-id>:<location>.<job-id>
   ```

2. Review the UDF code, copy it to a trusted bucket, and point future legacy SQL queries at that copy:

   ```bash
   gcloud storage cp gs://<untrusted-bucket>/<file> gs://<trusted-bucket>/<file>
   bq query --use_legacy_sql=true --udf_resource=gs://<trusted-bucket>/<file> '<query>'
   ```

Only the job's UDF resources are checked: inline UDF code, JavaScript libraries named in a GoogleSQL function's `library` option, and jobs run outside Terraform are not. Replace `<project-id>`, `<location>` and `<job-id>` with the job the finding names, `<untrusted-bucket>` and `<file>` with the UDF source it lists, `<trusted-bucket>` with an authorized bucket, and `<query>` with the query text.

## References

- [gcloud storage cp](https://docs.cloud.google.com/sdk/gcloud/reference/storage/cp)
- [bq cancel](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cancel)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [User-defined functions in legacy SQL](https://docs.cloud.google.com/bigquery/docs/user-defined-functions-legacy)
- [Manage jobs](https://docs.cloud.google.com/bigquery/docs/managing-jobs)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
For a UDF, use an unauthorized bucket; it should be detected.

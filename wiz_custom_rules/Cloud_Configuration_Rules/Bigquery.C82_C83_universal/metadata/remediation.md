# Remediation

The partitioned table in the finding accepts queries with no filter on its partitioning column, so a single query can scan every partition. Require a partition filter:

```bash
bq query --nouse_legacy_sql \
  'ALTER TABLE `<project-id>.<dataset>.<table>` SET OPTIONS (require_partition_filter = true)'
```

Queries on the table that do not filter on the partitioning column then fail with an error, so update any that rely on a full scan. Only tables declared in Terraform are checked; tables created with `bq`, the console or the API are not. Replace `<project-id>`, `<dataset>` and `<table>` with the table the finding names.

## References

- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Manage partitioned tables](https://docs.cloud.google.com/bigquery/docs/managing-partitioned-tables)
- [Query partitioned tables](https://docs.cloud.google.com/bigquery/docs/querying-partitioned-tables)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Create a table with an unauthorized configuration; it should be detected.

# Remediation

The dataset in the finding is in a location, or has a default table or partition expiration, that the rule does not authorize. Set an authorized expiration, or move the dataset to an authorized location.

- Expiration: set the value the finding names to one listed in `authorized_table_expirations_ms` or `authorized_partition_expirations_ms`. The rule lists milliseconds and `bq update` takes seconds, so divide by 1000. Pass only the flag you need:

  ```bash
  bq update --dataset --default_table_expiration=<table-seconds> \
    --default_partition_expiration=<partition-seconds> <project-id>:<dataset>
  ```

  The new defaults apply only to tables and partitions created afterward.

- Location: a dataset's location cannot be changed. Create a dataset in an authorized location, move the data into it as "Recreate datasets in another location" in Manage datasets describes, point its consumers at the new dataset, then delete the old one with its tables:

  ```bash
  bq mk --dataset --location=<location> <project-id>:<new-dataset>
  bq rm --recursive --dataset <project-id>:<dataset>
  ```

If the location or expiration is approved, add it to `authorized_locations`, `authorized_table_expirations_ms` or `authorized_partition_expirations_ms` in the rule's configuration instead. A dataset with no default expiration is not reported in this mode. Replace `<project-id>` and `<dataset>` with the dataset named in the finding, `<table-seconds>` and `<partition-seconds>` with authorized expirations in seconds, `<location>` with an authorized location, and `<new-dataset>` with the name of the replacement dataset.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [bq mk](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_mk)
- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [Update dataset properties](https://docs.cloud.google.com/bigquery/docs/updating-datasets)
- [Manage datasets](https://docs.cloud.google.com/bigquery/docs/managing-datasets)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Create a dataset with an unauthorized configuration; it should be detected.

# Remediation

The table in the finding has no expiration time, and its dataset gives it no default expiration, so BigQuery keeps it indefinitely. Set an expiration that matches the table's retention requirement:

```bash
bq update --expiration=<seconds> <project-id>:<dataset>.<table>
```

`<seconds>` counts from the time of the update; for example, `7776000` is 90 days. When the table expires, BigQuery deletes it along with all of its data. A table without its own expiration passes when its dataset, declared in the same Terraform source, sets a default table expiration, because a new table takes that default. Only tables declared in Terraform are checked; tables created with `bq`, the console or the API are not. Replace `<project-id>`, `<dataset>` and `<table>` with the table the finding names.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Manage tables](https://docs.cloud.google.com/bigquery/docs/managing-tables)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Set the expiration time of a BigQuery table to be outside its requirements; it should be detected.

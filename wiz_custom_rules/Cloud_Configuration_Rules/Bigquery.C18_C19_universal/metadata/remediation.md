# Remediation

The dataset in the finding has no default table expiration, so its tables are kept until someone deletes them, or its time travel window is longer than the rule allows. Fix the setting the finding names.

1. Set a default table expiration, in seconds. Tables created afterward are deleted that long after their creation:

   ```bash
   bq update --dataset --default_table_expiration=<seconds> <project-id>:<dataset>
   ```

   Tables that already exist keep their own expiration; set one with `bq update --expiration <seconds> <project-id>:<dataset>.<table>`.

2. Set the time travel window to at most `max_time_travel_hours` from the rule's configuration. BigQuery accepts 48 to 168 hours, in multiples of 24:

   ```bash
   bq update --dataset --max_time_travel_hours=<hours> <project-id>:<dataset>
   ```

Replace `<project-id>` and `<dataset>` with the dataset named in the finding, `<table>` with each of its tables, `<seconds>` with the retention your policy sets (at least 3600), and `<hours>` with the window.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Update dataset properties](https://docs.cloud.google.com/bigquery/docs/updating-datasets)
- [Data retention with time travel and fail-safe](https://docs.cloud.google.com/bigquery/docs/time-travel)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Create a dataset with an unauthorized configuration; it should be detected.

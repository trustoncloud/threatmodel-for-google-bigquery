# Remediation

The time travel window of the dataset in the finding is shorter than the rule requires, so changed or deleted data can be recovered for less time than your policy sets. Lengthen the window to at least `min_required_hours` from the rule's configuration:

```bash
bq update --dataset --max_time_travel_hours=<hours> <project-id>:<dataset>
```

The same change in SQL:

```sql
ALTER SCHEMA `<project-id>`.<dataset>
SET OPTIONS (max_time_travel_hours = <hours>);
```

Run it in the BigQuery console or with `bq query --nouse_legacy_sql`. BigQuery accepts 48 to 168 hours in multiples of 24, and a dataset that does not set the window gets 168. Replace `<project-id>` and `<dataset>` with the dataset named in the finding, and `<hours>` with the window.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Data retention with time travel and fail-safe](https://docs.cloud.google.com/bigquery/docs/time-travel)
- [Update dataset properties](https://docs.cloud.google.com/bigquery/docs/updating-datasets)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Set the time travel of a BigQuery dataset to an unauthorized value; it should be detected.

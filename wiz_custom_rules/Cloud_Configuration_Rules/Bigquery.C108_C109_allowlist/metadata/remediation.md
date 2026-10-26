# Remediation

The dataset in the finding is a linked dataset, created by subscribing to a BigQuery sharing listing, and its source dataset is not an authorized source. Either unsubscribe, or authorize the source.

To unsubscribe, delete the linked dataset. This does not delete the source dataset, and you can subscribe again later if the source is approved:

```bash
bq rm --recursive --dataset <project-id>:<dataset>
```

If the subscription is approved, add a pattern for its source, such as `^projects/<source-project-number>/datasets/<source-dataset>$`, to `authorized_source_dataset_patterns` in the rule's configuration instead; the source project appears as its project number. Replace `<project-id>` and `<dataset>` with the project and linked dataset named in the finding, and `<source-project-number>` and `<source-dataset>` with the source dataset the finding reports.

## References

- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [View and subscribe to listings and data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-view-subscribe-listings)
- [Manage subscriptions](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-subscriptions)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
1) Subscribe to an unauthorized listing and/or data exchange with an entity you control, or 2) subscribe with an unauthorized entity you control to a listing or exchange authorized for other entities you control; it should be detected.

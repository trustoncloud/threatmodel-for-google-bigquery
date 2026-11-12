# Remediation

The dataset in the finding has no backup label, or its label names a backup schedule the rule does not authorize. The label records the schedule the dataset is meant to be backed up on. Once the dataset is covered by an approved backup, such as scheduled table snapshots, label it with that schedule:

```bash
bq update --set_label backup_policy:<schedule> <project-id>:<dataset>
```

Use a value from `authorized_backup_schedules` for `<schedule>`, and the key set in `backup_label_key` if it is not `backup_policy`. If the schedule is approved, add it to `authorized_backup_schedules` in the rule's configuration instead. Replace `<project-id>` and `<dataset>` with the dataset named in the finding.

What the rule cannot show:

- The rule reads only the label. A label does not show that a backup exists, that it ran on schedule, or that it can be restored. Check that the schedule the label names actually runs, and test a restore.
- Tables and models are not checked. The label sits on the dataset, so a table or model without a snapshot or export gets no finding.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Updating labels](https://docs.cloud.google.com/bigquery/docs/updating-labels)
- [Introduction to table snapshots](https://docs.cloud.google.com/bigquery/docs/table-snapshots-intro)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Change the backup mechanism to be outside the requirements; it should be detected.

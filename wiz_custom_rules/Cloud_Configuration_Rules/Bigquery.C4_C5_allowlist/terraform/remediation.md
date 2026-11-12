Label the dataset with an authorized backup schedule from `authorized_backup_schedules`, under the key set in `backup_label_key`, or, if the schedule is approved, add it to `authorized_backup_schedules` in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  labels = { backup_policy = "daily" }
}
```

What the rule cannot show:

- The rule reads only the label, which records the schedule the dataset is meant to be backed up on. A label does not show that a backup exists, that it ran on schedule, or that it can be restored. Set it only once the dataset is covered by that backup.
- Tables and models are not checked. The label sits on the dataset, so a table or model without a snapshot or export gets no finding.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Label the dataset with an authorized backup schedule from `authorized_backup_schedules`, under the key set in `backup_label_key`, or, if the schedule is approved, add it to `authorized_backup_schedules` in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  labels = { backup_policy = "daily" }
}
```

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

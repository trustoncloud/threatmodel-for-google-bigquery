# Remediation

The dataset in the finding grants access to an entity that is not authorized: a user, group, domain, special group or IAM member, or an authorized view, routine or dataset. Remove the entry from the dataset's access list, or authorize the entity.

1. Export the dataset, including its access list:

   ```bash
   bq show --format=prettyjson <project-id>:<dataset> > dataset.json
   ```

2. Delete the entries for the entities the finding lists from the `access` array in `dataset.json`.

3. Apply the file. It replaces the dataset's whole access list:

   ```bash
   bq update --source dataset.json <project-id>:<dataset>
   ```

If the entity is approved, add it to `authorized_entities` in the rule's configuration instead, written as the finding lists it (for example `group:<email>` or `view:<table-id>`). Replace `<project-id>` and `<dataset>` with the dataset named in the finding. The rule reads only the dataset's access list: IAM policies on individual tables and views, and roles granted on the project, are not checked.

## References

- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Control access to resources with IAM](https://docs.cloud.google.com/bigquery/docs/control-access-to-resources-iam)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Configure an unauthorized IAM entity to have access to 1) a table or 2) a view; it should be detected.

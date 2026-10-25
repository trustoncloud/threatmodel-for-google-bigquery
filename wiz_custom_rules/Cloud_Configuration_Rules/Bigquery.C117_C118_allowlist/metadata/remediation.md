# Remediation

The dataset in the finding grants public access, grants access to an identity outside the authorized domains, or lacks an access entry the rule requires. Fix its access list.

1. Export the dataset, including its access list:

   ```bash
   bq show --format=prettyjson <project-id>:<dataset> > dataset.json
   ```

2. In the `access` array of `dataset.json`, delete the entries the finding names, including any `allUsers` or `allAuthenticatedUsers` entry, and add each entity from `required_entities` that is missing, with its role, for example `{"role": "OWNER", "groupByEmail": "<admin-group-email>"}`.

3. Apply the file. It replaces the dataset's whole access list:

   ```bash
   bq update --source dataset.json <project-id>:<dataset>
   ```

If an identity's domain is approved, add the domain to `authorized_domains` in the rule's configuration instead. Replace `<project-id>` and `<dataset>` with the dataset named in the finding, and `<admin-group-email>` with the group the rule requires. The rule reads only the dataset's access list, so access inherited from roles on the project is not checked.

## References

- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Control access to resources with IAM](https://docs.cloud.google.com/bigquery/docs/control-access-to-resources-iam)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
1) Allow an unauthorized access entity on a dataset, or 2) remove an authorized access entity on a dataset; it should be detected.

# Remediation

The dataset in the finding grants public access, grants access to a member that is not approved, or lacks an access entry the rule requires. Fix its access list.

1. Export the dataset, including its access list:

   ```bash
   bq show --format=prettyjson <project-id>:<dataset> > dataset.json
   ```

2. In the `access` array of `dataset.json`, delete the entries the finding names, including any `allUsers` or `allAuthenticatedUsers` entry, and add each entity from `required_entities` that is missing, with its role, for example `{"role": "OWNER", "groupByEmail": "<admin-group-email>"}`.

3. Apply the file. It replaces the dataset's whole access list:

   ```bash
   bq update --source dataset.json <project-id>:<dataset>
   ```

If a member is approved, add it to `authorized_access` in the rule's configuration instead:

- A user, a group or a domain-wide grant: its domain in `domains`, or its exact address in `emails`. `yourcompany.com` approves only that domain. Add `*.yourcompany.com` to approve its subdomains.
- A service account: its exact address in `service_accounts`, or the project that owns it in `project_ids`. A domain never approves a service account.
- A Google service agent, such as `service-<project-number>@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com`: its exact address in `service_accounts`.
- Any other member, such as a `principal://` identity: the exact member in `members`.

Replace `<project-id>` and `<dataset>` with the dataset named in the finding, and `<admin-group-email>` with the group the rule requires. The rule reads only the dataset's access list, so access inherited from roles on the project, folder or organization is not checked, and entries for authorized views, routines and datasets are not judged. A grant to a required entity that carries a condition holds only while the condition does, so it does not count as present: give each required entity its role with no condition.

## References

- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Control access to resources with IAM](https://docs.cloud.google.com/bigquery/docs/control-access-to-resources-iam)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
1) Allow an unauthorized access entity on a dataset, or 2) remove an authorized access entity on a dataset; it should be detected.

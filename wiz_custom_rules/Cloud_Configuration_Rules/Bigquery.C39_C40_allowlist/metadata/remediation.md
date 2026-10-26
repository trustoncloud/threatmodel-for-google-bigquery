# Remediation

BigQuery Omni is not disabled in the organization, or in the project not authorized to use Omni, in the finding: the constraint `bigquery.disableBQOmniAWS`, `bigquery.disableBQOmniAzure`, or both, is not enforced there. Enforce both at the organization:

```bash
gcloud resource-manager org-policies enable-enforce bigquery.disableBQOmniAWS \
  --organization=<organization-id>
gcloud resource-manager org-policies enable-enforce bigquery.disableBQOmniAzure \
  --organization=<organization-id>
```

A project is judged on the policy in effect on it, so a project finding under an organization that enforces both means the project, or a folder above it, turns the ban off: run the same commands with `--project=<project-id>` in place of `--organization`. An organization cannot be exempted. Once a project is approved for Omni, add its project ID to `authorized_omni_projects` in the rule's configuration instead; it can then lift the ban for itself, here for AWS (use `bigquery.disableBQOmniAzure` for Azure):

```bash
gcloud resource-manager org-policies disable-enforce bigquery.disableBQOmniAWS \
  --project=<project-id>
```

Replace `<organization-id>` with the organization in the finding, or the one that holds the project in the finding, and `<project-id>` with that project.

## References

- [gcloud resource-manager org-policies enable-enforce](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/org-policies/enable-enforce)
- [gcloud resource-manager org-policies disable-enforce](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/org-policies/disable-enforce)
- [Introduction to BigQuery Omni](https://docs.cloud.google.com/bigquery/docs/omni-introduction)
- [Organization policy constraints](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command syntax, flags and links.

## Testing Compliance
Use BigQuery Omni outside the requirements; it should be detected.

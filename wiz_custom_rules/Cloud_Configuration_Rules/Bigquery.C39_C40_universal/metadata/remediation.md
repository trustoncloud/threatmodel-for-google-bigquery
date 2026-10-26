# Remediation

BigQuery Omni is not disabled in the organization or project in the finding: the constraint `bigquery.disableBQOmniAWS`, `bigquery.disableBQOmniAzure`, or both, is not enforced there. Enforce both at the organization:

```bash
gcloud resource-manager org-policies enable-enforce bigquery.disableBQOmniAWS \
  --organization=<organization-id>
gcloud resource-manager org-policies enable-enforce bigquery.disableBQOmniAzure \
  --organization=<organization-id>
```

A project is judged on the policy in effect on it, so a project finding under an organization that enforces both means the project, or a folder above it, turns the ban off. Run the same commands with `--project=<project-id>` or `--folder=<folder-id>` in place of `--organization` to enforce them there. Replace `<organization-id>` with the organization in the finding, or the one that holds the project in the finding.

## References

- [gcloud resource-manager org-policies enable-enforce](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/org-policies/enable-enforce)
- [Introduction to BigQuery Omni](https://docs.cloud.google.com/bigquery/docs/omni-introduction)
- [Organization policy constraints](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command syntax, flags and links.

## Testing Compliance
Use BigQuery Omni outside the requirements; it should be detected.

# Remediation

A principal outside the authorized set holds a role on the policy tag in the finding, which can give it access to the columns that the tag protects. Remove the grant, or, once the principal is approved, add it to `authorized_principals` in the rule's configuration, written as in IAM (for example `group:analysts@example.com`).

1. List the policy tag's grants:

   ```bash
   gcloud data-catalog taxonomies policy-tags get-iam-policy <policy-tag> \
     --taxonomy=<taxonomy> --location=<location> --project=<project-id>
   ```

2. Remove each grant to a principal that is not authorized:

   ```bash
   gcloud data-catalog taxonomies policy-tags remove-iam-policy-binding <policy-tag> \
     --taxonomy=<taxonomy> --location=<location> --project=<project-id> \
     --member=<member> --role=<role>
   ```

Replace `<policy-tag>`, `<taxonomy>`, `<location>` and `<project-id>` with the policy tag in the finding and its taxonomy, location and project, and `<member>` and `<role>` with the grant it names, such as `user:jane@example.com` and `roles/datacatalog.categoryFineGrainedReader`. The rule has no cloud scan and judges only grants declared in Terraform, so use step 1 to review grants made outside Terraform.

## References

- [gcloud data-catalog taxonomies policy-tags get-iam-policy](https://docs.cloud.google.com/sdk/gcloud/reference/data-catalog/taxonomies/policy-tags/get-iam-policy)
- [gcloud data-catalog taxonomies policy-tags remove-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/data-catalog/taxonomies/policy-tags/remove-iam-policy-binding)
- [Restrict access with column-level access control](https://docs.cloud.google.com/bigquery/docs/column-level-security)
- [Introduction to column-level access control](https://docs.cloud.google.com/bigquery/docs/column-level-security-intro)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command syntax, flags and links.

## Testing Compliance
Configure an unauthorized IAM entity with access to a sensitive column; it should be detected.

# Remediation

A principal outside the authorized set holds a role on the BigQuery data policy in the finding, or holds the Masked Reader role on a project, folder or organization, which reaches every data policy below it. Either can let it read the column data the policies protect. Remove the grant, or, once the principal is approved, add it to `authorized_principals` in the rule's configuration, written as in IAM (for example `group:analysts@example.com`).

No GA `gcloud` or `bq` command manages a data policy's IAM policy, so use the BigQuery Data Policy API methods `getIamPolicy` and `setIamPolicy`. For a data policy on a policy tag, you can also remove the principal under **Manage Data Policies** on the console's Policy tag taxonomies page.

1. Read the data policy's IAM policy:

   ```bash
   curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" -d '{}' \
     "https://bigquerydatapolicy.googleapis.com/v1/projects/<project-id>/locations/<location>/dataPolicies/<data-policy-id>:getIamPolicy"
   ```

2. Save the returned policy to `request.json` as `{"policy": ...}`, with the unauthorized member removed and its `etag` kept, then apply it:

   ```bash
   curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" -d @request.json \
     "https://bigquerydatapolicy.googleapis.com/v1/projects/<project-id>/locations/<location>/dataPolicies/<data-policy-id>:setIamPolicy"
   ```

3. When the finding names the Masked Reader role on a project, folder or organization, remove it where it was granted:

   ```bash
   gcloud projects remove-iam-policy-binding <project-id> \
     --member=<member> --role=roles/bigquerydatapolicy.maskedReader
   ```

   ```bash
   gcloud resource-manager folders remove-iam-policy-binding <folder-id> \
     --member=<member> --role=roles/bigquerydatapolicy.maskedReader
   ```

   ```bash
   gcloud organizations remove-iam-policy-binding <organization-id> \
     --member=<member> --role=roles/bigquerydatapolicy.maskedReader
   ```

Replace `<project-id>`, `<location>` and `<data-policy-id>` with the data policy in the finding, `<folder-id>` and `<organization-id>` with the folder or organization the finding names, and `<member>` with the member it names, such as `user:jane@example.com`. The rule has no cloud scan and judges only grants declared in Terraform, so use step 1 to review grants made outside Terraform. On a project, folder or organization it matches only the predefined Masked Reader role: another role that carries the same permission, such as a custom role, is not read.

## References

- [gcloud projects remove-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/projects/remove-iam-policy-binding)
- [gcloud resource-manager folders remove-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/folders/remove-iam-policy-binding)
- [gcloud organizations remove-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/organizations/remove-iam-policy-binding)
- [Mask column data](https://docs.cloud.google.com/bigquery/docs/column-data-masking)
- [Introduction to data masking](https://docs.cloud.google.com/bigquery/docs/column-data-masking-intro)
- [Method: projects.locations.dataPolicies.setIamPolicy](https://docs.cloud.google.com/bigquery/docs/reference/bigquerydatapolicy/rest/v1/projects.locations.dataPolicies/setIamPolicy)

Checked 2026-11-11 with Google Cloud CLI 587.0.0: command syntax, flags and links.

## Testing Compliance
Configure an unauthorized IAM entity with access to a sensitive column in a data policy; it should be detected.

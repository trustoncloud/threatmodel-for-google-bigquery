# Remediation

A principal outside the authorized set holds a role on the BigQuery data policy in the finding, which can let it read the column data the policy protects. Remove the grant, or, once the principal is approved, add it to `authorized_principals` in the rule's configuration, written as in IAM (for example `group:analysts@example.com`).

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

Replace `<project-id>`, `<location>` and `<data-policy-id>` with the data policy in the finding. The rule has no cloud scan and judges only grants declared in Terraform, so use step 1 to review grants made outside Terraform.

## References

- [Mask column data](https://docs.cloud.google.com/bigquery/docs/column-data-masking)
- [Introduction to data masking](https://docs.cloud.google.com/bigquery/docs/column-data-masking-intro)
- [Method: projects.locations.dataPolicies.setIamPolicy](https://docs.cloud.google.com/bigquery/docs/reference/bigquerydatapolicy/rest/v1/projects.locations.dataPolicies/setIamPolicy)

Checked 2026-10-06: links.

## Testing Compliance
Configure an unauthorized IAM entity with access to a sensitive column in a data policy; it should be detected.

# Remediation

A role that can subscribe (`roles/analyticshub.subscriber` or `roles/analyticshub.admin`) on the data exchange or listing in the finding is granted to an identity outside the authorized domains. Remove that grant. No gcloud or bq command manages BigQuery sharing IAM, so use the Analytics Hub API's `getIamPolicy` and `setIamPolicy` methods on the exchange, or on the listing by adding `/listings/<listing-id>` after `<exchange-id>` in both URLs.

1. Save the current policy:

   ```bash
   curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" -d '{}' \
     "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>:getIamPolicy" > policy.json
   ```

2. In `policy.json`, delete the identity from the role's `members`, keep the `etag`, and wrap the whole policy as `{"policy": ...}`.

3. Write the policy back:

   ```bash
   curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" -d @policy.json \
     "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>:setIamPolicy"
   ```

Removing the role does not revoke subscriptions the identity already holds: list them with `projects.locations.dataExchanges.listSubscriptions` and revoke them with `projects.locations.subscriptions.revoke`. If the identity's domain is approved, add the domain (for example `example.com`) to `authorized_subscriber_domains` in the rule's configuration instead; a grant to `allUsers`, `allAuthenticatedUsers` or a `domain:` principal is always reported. The rule reads Terraform plans only, so a grant made outside Terraform, or at the project level, is not reported. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the data exchange or listing named in the finding.

## References

- [Configure BigQuery sharing roles](https://docs.cloud.google.com/bigquery/docs/analytics-hub-grant-roles)
- [Manage data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-exchanges)
- [Manage subscriptions](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-subscriptions)

Checked 2026-10-06: links.

## Testing Compliance
1) Add an unauthorized subscription, or 2) remove the authorized subscription from a listing and/or data exchange; it should be detected.

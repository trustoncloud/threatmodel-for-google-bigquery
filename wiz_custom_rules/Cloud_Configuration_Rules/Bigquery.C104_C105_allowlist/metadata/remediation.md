# Remediation

A role that can subscribe (`roles/analyticshub.subscriber` or `roles/analyticshub.admin`) on the data exchange or listing in the finding is granted to an identity that is not approved. Remove that grant. No gcloud or bq command manages BigQuery sharing IAM, so use the Analytics Hub API's `getIamPolicy` and `setIamPolicy` methods on the exchange, or on the listing by adding `/listings/<listing-id>` after `<exchange-id>` in both URLs.

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

Removing the role does not revoke subscriptions the identity already holds: list them with `projects.locations.dataExchanges.listSubscriptions` and revoke them with `projects.locations.subscriptions.revoke`. If the identity is approved, add it to `authorized_subscribers` in the rule's configuration instead: a user or group by its domain (for example `example.com`) under `domains` or its exact address under `emails`, and a service account by its exact address under `service_accounts` or its project under `project_ids`. A domain is matched exactly, so list `*.example.com` as well to approve its subdomains. A grant to `allUsers`, `allAuthenticatedUsers` or a whole domain (`domain:`) is always reported. A finding on a subscription means an account that is not approved already holds one: revoke that subscription the same way, then remove the grant that allowed it. A subscription to a whole data exchange names a contact the subscriber writes, so it is approved by the project that holds it: if that project is approved, add its project ID to `authorized_exchange_subscriber_project_ids`; otherwise revoke the subscription. Grants are read in Terraform source only, so a grant made outside Terraform, or at the project level, is not reported. Subscriptions are read where they are deployed, in projects that are scanned. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the data exchange or listing named in the finding.

## References

- [Configure BigQuery sharing roles](https://docs.cloud.google.com/bigquery/docs/analytics-hub-grant-roles)
- [Manage data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-exchanges)
- [Manage subscriptions](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-subscriptions)

Checked 2026-10-06: all links above resolve.

## Testing Compliance
1) Add an unauthorized subscription, or 2) remove the authorized subscription from a listing and/or data exchange; it should be detected.

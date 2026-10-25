# Remediation

The data exchange or listing in the finding has no primary contact, or its contact is outside the authorized email domains. Set the primary contact to an email address in an authorized domain. No gcloud or bq command manages BigQuery sharing, so call the Analytics Hub API's `projects.locations.dataExchanges.patch` method:

```bash
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"primaryContact": "<contact-email>"}' \
  "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>?updateMask=primaryContact"
```

For a listing, send the same request to the `projects.locations.dataExchanges.listings.patch` method by adding `/listings/<listing-id>` after `<exchange-id>` in the URL. If the contact's domain is approved, add it with its leading `@` (for example `@example.com`) to `authorized_contact_domains` in the rule's configuration instead (`authorized_contact_domains` for the Terraform matcher). The cloud matcher reads data exchanges only; listing contacts are checked in Terraform plans. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the data exchange or listing named in the finding, and `<contact-email>` with an address in an authorized domain.

## References

- [Manage data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-exchanges)
- [Manage listings](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-listings)

Checked 2026-10-06: links.

## Testing Compliance
For a listing or data exchange, use an unauthorized email; it should be detected.

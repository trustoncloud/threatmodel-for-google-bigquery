# Remediation

The display name, description or documentation of the listing in the finding matches a sensitive-data pattern (an API key, access key, email address, password, secret or SSN). Remove the value, and rotate any credential it exposed, since anyone who can view the listing can read these fields. No gcloud or bq command manages BigQuery sharing listings, so rewrite each affected field with the Analytics Hub API's `projects.locations.dataExchanges.listings.patch` method:

```bash
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"description": "<cleaned-text>"}' \
  "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>/listings/<listing-id>?updateMask=description"
```

For the other fields, use `displayName` or `documentation` in both the body and the update mask. If a match is approved content, such as a public support address, narrow or remove that pattern in `sensitive_patterns` in the rule's configuration instead. The rule reads Terraform plans only, so a listing edited outside Terraform is not reported. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the listing named in the finding and its data exchange, and `<cleaned-text>` with the field's text without the sensitive value.

## References

- [Manage listings](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-listings)

Checked 2026-10-06: links.

## Testing Compliance
Add sensitive data to a field of a listing; it should be detected.

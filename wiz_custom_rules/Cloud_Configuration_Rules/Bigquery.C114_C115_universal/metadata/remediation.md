# Remediation

The listing in the finding does not restrict data export, or restricts it without restricting query results. Turn on both. No gcloud or bq command manages BigQuery sharing listings, so call the Analytics Hub API's `projects.locations.dataExchanges.listings.patch` method:

```bash
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"restrictedExportConfig": {"enabled": true, "restrictQueryResult": true}}' \
  "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>/listings/<listing-id>?updateMask=restrictedExportConfig"
```

Subscribers can then no longer copy or export the shared data or its query results. Deployed listings are read where they are scanned; a listing in a multi-region location may not be among them, and the Terraform check covers it. It checks listings that share a BigQuery dataset; a listing that shares only a Pub/Sub topic is not checked, because restricted export applies to a shared dataset. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the listing named in the finding and its data exchange.

## References

- [Manage listings](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-listings)
- [Introduction to BigQuery sharing](https://docs.cloud.google.com/bigquery/docs/analytics-hub-introduction)

Checked 2026-10-06: all links above resolve.

## Testing Compliance
Enable the restricted export for listings outside the requirements; it should be detected.

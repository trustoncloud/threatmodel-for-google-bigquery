# Remediation

The listing in the finding is publicly discoverable, allows data export without being approved for it, or has no description or documentation. No gcloud or bq command manages BigQuery sharing listings, so fix it with the Analytics Hub API's `projects.locations.dataExchanges.listings.patch` method, applying the steps that match the finding in this order:

1. Make the listing private. If its exchange is public, make the exchange private instead with `projects.locations.dataExchanges.patch`, since a public exchange cannot hold private listings.

   ```bash
   curl -X PATCH \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{"discoveryType": "DISCOVERY_TYPE_PRIVATE"}' \
     "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>/listings/<listing-id>?updateMask=discoveryType"
   ```

2. Turn on restricted export and add a description and documentation:

   ```bash
   curl -X PATCH \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{"restrictedExportConfig": {"enabled": true}, "description": "<description>", "documentation": "<documentation>"}' \
     "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>/listings/<listing-id>?updateMask=restrictedExportConfig,description,documentation"
   ```

If the listing is approved to allow export, add its listing ID to `authorized_exportable_listing_ids` in the rule's configuration and leave `restrictedExportConfig` out of step 2. The rule reads Terraform plans only, so a listing changed outside Terraform is not reported. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the listing named in the finding and its data exchange, and `<description>` and `<documentation>` with text for subscribers.

## References

- [Manage listings](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-listings)
- [Introduction to BigQuery sharing](https://docs.cloud.google.com/bigquery/docs/analytics-hub-introduction)

Checked 2026-10-06: links.

## Testing Compliance
Create a listing with an unauthorized configuration; it should be detected.

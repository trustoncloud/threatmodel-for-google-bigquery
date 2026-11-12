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

If the listing is approved to allow export, add it to the rule's configuration and leave `restrictedExportConfig` out of step 2: its listing ID in `authorized_exportable_listing_ids` for the Terraform check, and its full name with the project number in `authorized_exportable_listing_names` for the check of deployed listings. Deployed listings are read where they are scanned; a listing in a multi-region location may not be among them, and the Terraform check covers it. A listing that leaves out its discovery type takes the one of its exchange. The rule reads the exchange when it is declared in the scanned files; an exchange managed elsewhere must be listed in `authorized_private_exchange_names_by_project_id`, or the listing is reported. IAM grants on the exchange are not read. Restricted export is checked on listings that share a BigQuery dataset. Replace `<project-id>`, `<location>`, `<exchange-id>` and `<listing-id>` with the listing named in the finding and its data exchange, and `<description>` and `<documentation>` with text for subscribers.

## References

- [Manage listings](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-listings)
- [Introduction to BigQuery sharing](https://docs.cloud.google.com/bigquery/docs/analytics-hub-introduction)

Checked 2026-10-06: all links above resolve.

## Testing Compliance
Create a listing with an unauthorized configuration; it should be detected.

# Remediation

The data exchange in the finding is publicly discoverable in the BigQuery sharing catalog, and no exchange may be. Set its discovery type to private. No gcloud or bq command manages BigQuery sharing, so call the Analytics Hub API's `projects.locations.dataExchanges.patch` method:

```bash
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"discoveryType": "DISCOVERY_TYPE_PRIVATE"}' \
  "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>?updateMask=discoveryType"
```

The change also applies to every listing in the exchange. Discovery does not control access, which comes from IAM, so also remove `allUsers` and `allAuthenticatedUsers` from the exchange's IAM policy with the `projects.locations.dataExchanges.getIamPolicy` and `setIamPolicy` methods. Replace `<project-id>`, `<location>` and `<exchange-id>` with the project, location and ID of the data exchange named in the finding.

## References

- [Manage data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-exchanges)
- [Configure BigQuery sharing roles](https://docs.cloud.google.com/bigquery/docs/analytics-hub-grant-roles)

Checked 2026-10-06: links.

## Testing Compliance
Create a data exchange with an unauthorized configuration; it should be detected.

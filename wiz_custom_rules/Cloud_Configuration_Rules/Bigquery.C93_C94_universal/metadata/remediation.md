# Remediation

The data exchange in the finding is a standard exchange, and every data exchange must be a data clean room. The sharing environment is chosen when an exchange is created and is not among the fields an update can change, so create a data clean room, move the shared data into it, and delete the old exchange. No gcloud or bq command manages BigQuery sharing, so the steps call the Analytics Hub API.

1. Create the data clean room in the same location with the `projects.locations.dataExchanges.create` method:

   ```bash
   curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{"displayName": "<display-name>", "sharingEnvironmentConfig": {"dcrExchangeConfig": {}}}' \
     "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges?dataExchangeId=<clean-room-id>"
   ```

2. Publish the tables and views the old exchange shares as listings in the clean room (a clean room shares tables, views and table-valued functions, and cannot take a whole dataset), and grant its subscribers access there.

3. Delete the old exchange with the `projects.locations.dataExchanges.delete` method. This also deletes its listings, so subscribers lose access through them, and it cannot be undone. If the exchange has listings for multiple regions, revoke their active subscriptions first.

   ```bash
   curl -X DELETE \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/dataExchanges/<exchange-id>"
   ```

Replace `<project-id>`, `<location>` and `<exchange-id>` with the project, location and ID of the data exchange named in the finding, and `<clean-room-id>` and `<display-name>` with an ID (letters, numbers and underscores) and a display name for the new clean room.

## References

- [Share sensitive data with data clean rooms](https://docs.cloud.google.com/bigquery/docs/data-clean-rooms)
- [Manage data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-exchanges)

Checked 2026-10-06: links.

## Testing Compliance
Configure a data exchange required to be a data clean room as a non-data clean room; it should be detected.

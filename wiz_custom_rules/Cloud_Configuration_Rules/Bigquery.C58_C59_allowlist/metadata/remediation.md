# Remediation

The external table in the finding caches its metadata with a cache mode or a maximum staleness outside the authorized settings (by default, cache mode `AUTOMATIC` or `MANUAL`, and staleness between 30 minutes and 7 days). Update the table's metadata caching settings:

1. Save the cache mode in a table definition file, `cache.json`:

   ```json
   {
     "metadataCacheMode": "AUTOMATIC"
   }
   ```

2. Apply it with a staleness inside the window, here 4 hours:

   ```bash
   bq update --max_staleness='0-0 0 4:0:0' \
     --external_table_definition=cache.json <project-id>:<dataset>.<table>
   ```

If other settings are approved, change `authorized_metadata_cache_modes`, `min_staleness_seconds` or `max_staleness_seconds` in the rule's configuration instead. Only tables declared in Terraform are checked, and only those that set a cache mode. Replace `<project-id>`, `<dataset>` and `<table>` with the table the finding names.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [Create Cloud Storage BigLake tables](https://docs.cloud.google.com/bigquery/docs/create-cloud-storage-table-biglake)
- [Use metadata caching for external data sources](https://docs.cloud.google.com/bigquery/docs/metadata-caching-external-tables)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Set the metadata cache mode and staleness of an external table outside the requirements; it should be detected.

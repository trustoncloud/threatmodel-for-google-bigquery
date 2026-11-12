Point external tables and load jobs at a source in `authorized_source_gcs` (or, for a source outside Cloud Storage such as Google Drive, on a host in `authorized_source_hosts`), and extract jobs at a destination in `authorized_destination_gcs`. A job may read only the BigQuery tables in `authorized_source_tables_by_project_id` and write only those in `authorized_destination_tables_by_project_id`. Once a location or table is approved, add it to the matching list in the rule's configuration:

```hcl
resource "google_bigquery_table" "example" {
  external_data_configuration {
    source_uris = ["gs://<approved-source-bucket>/<path>"]
  }
}

resource "google_bigquery_job" "load" {
  load {
    source_uris = ["gs://<approved-source-bucket>/<path>"]

    destination_table {
      project_id = "<project-id>"
      dataset_id = "<approved-destination-dataset>"
      table_id   = "<approved-destination-table>"
    }
  }
}

resource "google_bigquery_job" "extract" {
  extract {
    destination_uris = ["gs://<approved-destination-bucket>/<path>"]

    source_table {
      project_id = "<project-id>"
      dataset_id = "<approved-source-dataset>"
      table_id   = "<approved-source-table>"
    }
  }
}
```

The table lists take `projects/<project-id>/datasets/<dataset>/tables/<table>`, with the project ID. An entry that stops at the dataset, `projects/<project-id>/datasets/<dataset>`, approves every table and model in it. The rule reads a load job's `destination_table`, an extract job's `source_table` or `source_model`, a copy job's `source_tables` and `destination_table`, and a query job's `destination_table`. The same dataset or table ID in another project is a different table, so it is reported. A query job with no `destination_table` writes to a temporary table and is not reported.

Sources and destinations are separate lists, so a bucket approved for reading is not approved for exports until it is in both. `gs://<bucket>` approves the whole bucket and `gs://<bucket>/<folder>/` only what is inside that folder; a bucket with a longer name, a folder next to the approved one or a wildcard above it is reported. A host matches exactly, and `*.example.com` approves its subdomains.

A job cannot be changed once it has run and its ID cannot be reused, so give the corrected job a new `job_id`.

Four limits of a source scan:

- A URI or a table set from a variable or another resource is not known until apply, so it is reported. Write the value in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- A table must be stated in full: `project_id`, `dataset_id` and `table_id` as literal values, or `table_id` as a full path (`projects/<project-id>/datasets/<dataset>/tables/<table>`). A table that leaves `project_id` to the provider is reported, and so is a job that builds its tables with a `dynamic` block.
- The SQL of a query job is not read, so the tables it selects from are not checked. Only its `destination_table` is.
- The rule covers external table sources and the endpoints of declared jobs. Datasets, models, connections and Analytics Hub listings are not read.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)
- [google_bigquery_job (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_job)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

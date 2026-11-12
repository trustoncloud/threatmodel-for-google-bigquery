Declare each column that `sensitive_columns` lists for the table with type `BYTES`, the type that holds AEAD ciphertext:

```hcl
resource "google_bigquery_table" "example" {
  dataset_id = "hr_data"
  table_id   = "employees"
  schema     = <<EOF
[
  {"name": "ssn", "type": "BYTES", "mode": "NULLABLE"}
]
EOF
}
```

Changing a column's type in `schema` makes Terraform replace the table, so encrypt the live column first, then declare it as `BYTES`. A declared query job whose text names a table in `sensitive_table_refs` must call `AEAD.ENCRYPT` or `DETERMINISTIC_ENCRYPT`; the matcher looks only for those names, so a query that only decrypts is still reported. A table is named when its dataset and table ID appear side by side in the SQL text, with or without a project in front and with or without backticks, in any case. A table with a longer name, such as `hr_data.employees_archive`, is a different table and is not reported.

`sensitive_columns` lists each table as `dataset.table`, compared exactly with the table's `dataset_id` and `table_id`. Write `project.dataset.table` to limit an entry to one project, or the table ID alone to cover that table ID in every dataset. A `dataset_id` that points at a `google_bigquery_dataset` in the same scan is resolved. The reference is resolved to the dataset resource in the same file, or, when that file declares none, to the only dataset resource with that name in the scan. If two other files declare the name, or that dataset's own `dataset_id` comes from a variable with no default, the dataset is not known. A dataset or project the source does not state (a variable with no default, or the provider's default project) is treated as the listed one, so that table is still checked. A variable that declares a default is checked at that default, because the scan reads the Terraform source. When the default names a dataset outside the list and Terraform deploys a listed dataset in its place, the table is not checked and the scan passes: write `dataset_id` and `project` as literal values for a table that holds sensitive columns.

What the rule cannot show:

- A `BYTES` column can hold any bytes. The type shows that the column can store ciphertext. It does not show that the values in it are encrypted.
- The query text is not parsed. A query passes when `AEAD.ENCRYPT` or `DETERMINISTIC_ENCRYPT` appears anywhere in it, even in a comment or applied to another column.
- A schema loaded with `file()` or built with `jsonencode()` is not in the source as text, so its column types cannot be read. A listed table that declares its schema this way is reported: write the schema as JSON text in the resource. A listed table that declares no `schema` at all is not reported, and its columns are not checked.
- A query is read only when its text is written in the resource. A query loaded with `file()` or set from a variable with no default is not checked, and neither is a table reached through a wildcard (`hr_data.employee*`) or through a name built when the query runs.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

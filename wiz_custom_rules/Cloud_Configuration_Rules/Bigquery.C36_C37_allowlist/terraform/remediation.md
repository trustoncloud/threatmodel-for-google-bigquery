Declare each column that `sensitive_columns` lists for the table's `table_id` with type `BYTES`, holding AEAD ciphertext:

```hcl
resource "google_bigquery_table" "example" {
  table_id = "employees"
  schema   = <<EOF
[
  {"name": "ssn", "type": "BYTES", "mode": "NULLABLE"}
]
EOF
}
```

Changing a column's type in `schema` makes Terraform replace the table, so encrypt the live column first, then declare it as `BYTES`. A declared query job whose text names a table in `sensitive_table_refs` must call `AEAD.ENCRYPT` or `DETERMINISTIC_ENCRYPT`; the matcher looks only for those names, so a query that only decrypts is still reported.

## References

- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

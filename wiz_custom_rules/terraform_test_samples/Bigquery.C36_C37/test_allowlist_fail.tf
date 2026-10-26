# Bigquery.C37 (bigquery_aead_enforcement) - allowlist - VIOLATING

# Sensitive column declared as plaintext STRING: 1 finding
resource "google_bigquery_table" "employees" {
  dataset_id = "hr_data"
  table_id   = "employees"

  schema = <<EOF
[
  {"name": "id", "type": "INTEGER", "mode": "REQUIRED"},
  {"name": "ssn", "type": "STRING", "mode": "NULLABLE"},
  {"name": "salary", "type": "BYTES", "mode": "NULLABLE"}
]
EOF
}

# Sensitive table read in plaintext: 1 finding
resource "google_bigquery_job" "plaintext_read" {
  job_id = "plaintext_read"

  query {
    query                = "SELECT ssn FROM finance.credit_cards WHERE region = 'AU'"
    maximum_bytes_billed = "1000000000"
  }
}

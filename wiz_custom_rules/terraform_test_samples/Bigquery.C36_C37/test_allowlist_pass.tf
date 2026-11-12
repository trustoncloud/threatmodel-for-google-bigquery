# Bigquery.C37 (bigquery_aead_enforcement) - allowlist - COMPLIANT

# Sensitive columns declared BYTES, the type that holds AEAD ciphertext
resource "google_bigquery_table" "employees" {
  dataset_id = "hr_data"
  table_id   = "employees"

  schema = <<EOF
[
  {"name": "id", "type": "INTEGER", "mode": "REQUIRED"},
  {"name": "ssn", "type": "BYTES", "mode": "NULLABLE"},
  {"name": "salary", "type": "BYTES", "mode": "NULLABLE"},
  {"name": "region", "type": "STRING", "mode": "NULLABLE"}
]
EOF
}

# Same table ID in a dataset that is not listed: not a sensitive table
resource "google_bigquery_table" "sandbox_employees" {
  dataset_id = "training_sandbox"
  table_id   = "employees"

  schema = <<EOF
[
  {"name": "id", "type": "INTEGER", "mode": "REQUIRED"},
  {"name": "salary", "type": "NUMERIC", "mode": "NULLABLE"}
]
EOF
}

# Same table ID, in a dataset the scan resolves to one that is not listed
resource "google_bigquery_dataset" "sandbox" {
  dataset_id = "training_sandbox"
  location   = "US"
}

resource "google_bigquery_table" "sandbox_cards" {
  dataset_id = google_bigquery_dataset.sandbox.dataset_id
  table_id   = "credit_cards"

  schema = <<EOF
[
  {"name": "card_number", "type": "STRING", "mode": "NULLABLE"}
]
EOF
}

# Sensitive table handled with AEAD encryption
resource "google_bigquery_job" "encrypted_write" {
  job_id = "encrypted_write"

  query {
    query                = "INSERT INTO hr_data.employees SELECT id, AEAD.ENCRYPT(keys.k, ssn, '') FROM staging.raw"
    maximum_bytes_billed = "1000000000"
  }
}

# Deterministic AEAD is part of the documented function family
resource "google_bigquery_job" "deterministic_write" {
  job_id = "deterministic_write"

  query {
    query                = "INSERT INTO finance.credit_cards SELECT DETERMINISTIC_ENCRYPT(keys.k, card_number, '') FROM staging.cards"
    maximum_bytes_billed = "1000000000"
  }
}

# Query touching only non-sensitive tables
resource "google_bigquery_job" "public_report" {
  job_id = "public_report"

  query {
    query                = "SELECT region, COUNT(*) FROM analytics_data.orders GROUP BY region"
    maximum_bytes_billed = "1000000000"
  }
}

# Tables whose names only contain a sensitive table's name
resource "google_bigquery_job" "archive_report" {
  job_id = "archive_report"

  query {
    query                = "SELECT a.region FROM hr_data.employees_archive a JOIN shr_data.employees b ON a.id = b.id"
    maximum_bytes_billed = "1000000000"
  }
}

# A table that is not listed may load its schema from a file
variable "schema_file" {
  type = string
}

resource "google_bigquery_table" "sandbox_file_schema" {
  dataset_id = "training_sandbox"
  table_id   = "events"
  schema     = file(var.schema_file)
}

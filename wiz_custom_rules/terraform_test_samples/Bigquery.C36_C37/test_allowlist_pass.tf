# Bigquery.C37 (bigquery_aead_enforcement) - allowlist - COMPLIANT

# Sensitive columns stored as ciphertext (BYTES)
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

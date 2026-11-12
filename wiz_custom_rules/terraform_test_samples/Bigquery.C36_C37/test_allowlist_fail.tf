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

# Sensitive table whose dataset is a reference to a listed dataset in the
# scan: 1 finding
resource "google_bigquery_dataset" "finance" {
  dataset_id = "finance"
  location   = "US"
}

resource "google_bigquery_table" "credit_cards" {
  dataset_id = google_bigquery_dataset.finance.dataset_id
  table_id   = "credit_cards"

  schema = <<EOF
[
  {"name": "card_number", "type": "STRING", "mode": "NULLABLE"}
]
EOF
}

# BigQuery column names ignore case, so SSN is the listed column: 1 finding
resource "google_bigquery_table" "employees_staging" {
  project    = "hr-staging"
  dataset_id = "hr_data"
  table_id   = "employees"

  schema = <<EOF
[
  {"name": "SSN", "type": "STRING", "mode": "NULLABLE"}
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

# Sensitive table named with each part in backticks: 1 finding
resource "google_bigquery_job" "quoted_read" {
  job_id = "quoted_read"

  query {
    query                = "SELECT ssn FROM `hr_data`.`employees`"
    maximum_bytes_billed = "1000000000"
  }
}

# Sensitive table named with its project and in another case: 1 finding
resource "google_bigquery_job" "project_qualified_read" {
  job_id = "project_qualified_read"

  query {
    query                = "SELECT card_number FROM `my-project.Finance.Credit_Cards`"
    maximum_bytes_billed = "1000000000"
  }
}

# Sensitive table whose schema is loaded from a file, so its column types
# cannot be read: 1 finding
variable "schema_file" {
  type = string
}

resource "google_bigquery_table" "employees_file_schema" {
  project    = "hr-prod"
  dataset_id = "hr_data"
  table_id   = "employees"
  schema     = file(var.schema_file)
}

# Sensitive table whose schema is built with jsonencode(): 1 finding
resource "google_bigquery_table" "cards_built_schema" {
  project    = "finance-prod"
  dataset_id = "finance"
  table_id   = "credit_cards"

  schema = jsonencode([
    { name = "card_number", type = "STRING", mode = "NULLABLE" }
  ])
}

# Bigquery.C24 (bigquery_authorized_data_flow) - allowlist - COMPLIANT

resource "google_bigquery_table" "lake_table" {
  dataset_id = "analytics_data"
  table_id   = "lake_table"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://my-corp-data-lake/facts/*"]
  }
}

resource "google_bigquery_job" "load_from_partner" {
  job_id = "load_from_partner"

  load {
    source_uris = ["gs://partner-upload-bucket/incoming/*.csv"]

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "partner_feed"
    }
  }
}

resource "google_bigquery_job" "extract_to_lake" {
  job_id = "extract_to_lake"

  extract {
    destination_uris = ["gs://my-corp-data-lake/exports/out-*.avro"]

    source_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

# A Google Sheets source on the approved host
resource "google_bigquery_table" "sheet_table" {
  dataset_id = "analytics_data"
  table_id   = "sheet_table"

  external_data_configuration {
    autodetect    = true
    source_format = "GOOGLE_SHEETS"
    source_uris   = ["https://drive.google.com/open?id=1AbCdEfGhIjKlMnOpQrStUvWxYz"]
  }
}

# A copy job between approved tables: the source by its dataset, the
# destination by its full name
resource "google_bigquery_job" "copy_facts" {
  job_id = "copy_facts"

  copy {
    source_tables {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "partner_feed"
    }
  }
}

# A query job writing to an approved table, written as a full path
resource "google_bigquery_job" "query_to_feed" {
  job_id = "query_to_feed"

  query {
    query = "SELECT * FROM analytics_data.facts"

    destination_table {
      table_id = "projects/my-project/datasets/analytics_data/tables/partner_feed"
    }
  }
}

# A query job with no destination table writes to a temporary table
resource "google_bigquery_job" "query_plain" {
  job_id = "query_plain"

  query {
    query = "SELECT COUNT(*) FROM analytics_data.facts"
  }
}

# An extract job reading a model in an approved dataset
resource "google_bigquery_job" "extract_model" {
  job_id = "extract_model"

  extract {
    destination_uris = ["gs://my-corp-data-lake/exports/model-*"]

    source_model {
      project_id = "my-project"
      dataset_id = "analytics_data"
      model_id   = "churn"
    }
  }
}

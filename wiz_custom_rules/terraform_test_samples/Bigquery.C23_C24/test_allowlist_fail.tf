# Bigquery.C24 (bigquery_authorized_data_flow) - allowlist - VIOLATING

# External table reading an unauthorized bucket: 1 finding
resource "google_bigquery_table" "shadow_table" {
  dataset_id = "analytics_data"
  table_id   = "shadow_table"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris   = ["gs://unknown-vendor-drop/raw/*.csv"]
  }
}

# Extract job writing to an unauthorized destination: 1 finding
resource "google_bigquery_job" "exfil_extract" {
  job_id = "exfil_extract"

  extract {
    destination_uris = ["gs://personal-backup-bucket/dump-*.json"]

    source_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

# Buckets whose names start with an approved bucket's name: 2 findings
resource "google_bigquery_table" "lookalike_bucket" {
  dataset_id = "analytics_data"
  table_id   = "lookalike_bucket"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"

    source_uris = [
      "gs://my-corp-data-lake-rogue/object.csv",
      "gs://my-corp-data-lakex/object.csv",
    ]
  }
}

# A folder next to the approved source folder: 1 finding
resource "google_bigquery_job" "load_from_sibling_folder" {
  job_id = "load_from_sibling_folder"

  load {
    source_uris = ["gs://partner-upload-bucket/incoming-old/feed.csv"]

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "partner_feed"
    }
  }
}

# A bucket approved as a source only, used as an export destination: 1 finding
resource "google_bigquery_job" "extract_to_source_bucket" {
  job_id = "extract_to_source_bucket"

  extract {
    destination_uris = ["gs://partner-upload-bucket/incoming/out-*.csv"]

    source_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

# Destinations outside the approved export folder: a folder next to it, a
# wildcard above it and a lookalike bucket: 3 findings
resource "google_bigquery_job" "extract_outside_folder" {
  job_id = "extract_outside_folder"

  extract {
    destination_uris = [
      "gs://my-corp-data-lake/exports-old/out-*.avro",
      "gs://my-corp-data-lake/*",
      "gs://my-corp-data-lake-rogue/exports/out-*.avro",
    ]

    source_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

# Hosts that only look like the approved host: 2 findings
resource "google_bigquery_table" "lookalike_host" {
  dataset_id = "analytics_data"
  table_id   = "lookalike_host"

  external_data_configuration {
    autodetect    = true
    source_format = "GOOGLE_SHEETS"

    source_uris = [
      "https://drive.google.com.evil.example/open?id=1",
      "https://drive.google.com@evil.example/open?id=1",
    ]
  }
}

# A source set from a variable with no default is not known until apply: 1 finding
variable "source_bucket" {
  type = string
}

resource "google_bigquery_table" "unresolved_source" {
  dataset_id = "analytics_data"
  table_id   = "unresolved_source"

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris   = ["gs://${var.source_bucket}/facts/*.csv"]
  }
}

# A load job writing to a table that is not an approved destination: 1 finding
resource "google_bigquery_job" "load_to_other_table" {
  job_id = "load_to_other_table"

  load {
    source_uris = ["gs://partner-upload-bucket/incoming/*.csv"]

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "partner_feed_2"
    }
  }
}

# An extract job reading the approved dataset ID in another project: 1 finding
resource "google_bigquery_job" "extract_from_other_project" {
  job_id = "extract_from_other_project"

  extract {
    destination_uris = ["gs://my-corp-data-lake/exports/out-*.avro"]

    source_table {
      project_id = "my-project-2"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }
  }
}

# An extract job reading a model in a dataset that is not approved: 1 finding
resource "google_bigquery_job" "extract_other_model" {
  job_id = "extract_other_model"

  extract {
    destination_uris = ["gs://my-corp-data-lake/exports/model-*"]

    source_model {
      project_id = "my-project"
      dataset_id = "ml_models"
      model_id   = "churn"
    }
  }
}

# A copy job: one source in a dataset with a longer name, and a destination
# in a dataset that is not approved: 2 findings
resource "google_bigquery_job" "copy_out" {
  job_id = "copy_out"

  copy {
    source_tables {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "facts"
    }

    source_tables {
      project_id = "my-project"
      dataset_id = "analytics_data_2"
      table_id   = "facts"
    }

    destination_table {
      project_id = "my-project"
      dataset_id = "scratch"
      table_id   = "facts_copy"
    }
  }
}

# A query job writing its result to a table in another project, with the
# table written as a full path: 1 finding
resource "google_bigquery_job" "query_to_other_project" {
  job_id = "query_to_other_project"

  query {
    query = "SELECT * FROM analytics_data.facts"

    destination_table {
      table_id = "projects/vendor-project/datasets/analytics_data/tables/partner_feed"
    }
  }
}

# A destination that leaves out project_id cannot be matched: 1 finding
resource "google_bigquery_job" "load_no_project" {
  job_id = "load_no_project"

  load {
    source_uris = ["gs://partner-upload-bucket/incoming/*.csv"]

    destination_table {
      dataset_id = "analytics_data"
      table_id   = "partner_feed"
    }
  }
}

# A destination set from a variable with no default is not known until apply: 1 finding
variable "target_table" {
  type = string
}

resource "google_bigquery_job" "load_variable_table" {
  job_id = "load_variable_table"

  load {
    source_uris = ["gs://partner-upload-bucket/incoming/*.csv"]

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = var.target_table
    }
  }
}

# Source tables built by a dynamic block cannot be read: 1 finding
variable "copy_sources" {
  type = list(object({ project_id = string, dataset_id = string, table_id = string }))
}

resource "google_bigquery_job" "copy_dynamic_sources" {
  job_id = "copy_dynamic_sources"

  copy {
    dynamic "source_tables" {
      for_each = var.copy_sources

      content {
        project_id = source_tables.value.project_id
        dataset_id = source_tables.value.dataset_id
        table_id   = source_tables.value.table_id
      }
    }

    destination_table {
      project_id = "my-project"
      dataset_id = "analytics_data"
      table_id   = "partner_feed"
    }
  }
}

# Bigquery.C21 (bigquery_dlp_protection) - allowlist - COMPLIANT

resource "google_data_loss_prevention_job_trigger" "bq_scan" {
  parent       = "projects/example-project"
  display_name = "bq-pii-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1"

    storage_config {
      big_query_options {
        table_reference {
          project_id = "example-project"
          dataset_id = "analytics_data"
          table_id   = "orders"
        }
      }
    }

    actions {
      publish_summary_to_cscc {}
    }
  }
}

# Trigger scanning GCS, not BigQuery: out of scope
resource "google_data_loss_prevention_job_trigger" "gcs_scan" {
  parent       = "projects/example-project"
  display_name = "gcs-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/other-template"

    storage_config {
      cloud_storage_options {
        file_set {
          url = "gs://trusted-corp-lake/**"
        }
      }
    }

    actions {
      publish_summary_to_cscc {}
    }
  }
}

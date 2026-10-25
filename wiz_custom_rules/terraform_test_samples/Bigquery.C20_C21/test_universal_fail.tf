# Bigquery.C21 (bigquery_dlp_protection) - universal - VIOLATING

# BigQuery trigger with neither a template nor inline rules: 1 finding
resource "google_data_loss_prevention_job_trigger" "ruleless" {
  parent       = "projects/example-project"
  display_name = "ruleless-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
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

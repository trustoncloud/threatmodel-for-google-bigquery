# Bigquery.C21 (bigquery_dlp_protection) - allowlist - VIOLATING

# BigQuery trigger using an unauthorized template: 1 finding
resource "google_data_loss_prevention_job_trigger" "rogue_template" {
  parent       = "projects/example-project"
  display_name = "rogue-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/example-project/inspectTemplates/homemade-v0"

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

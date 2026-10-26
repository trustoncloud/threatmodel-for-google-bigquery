# Bigquery.C21 (bigquery_dlp_protection) - universal - COMPLIANT

# Managed template reference
resource "google_data_loss_prevention_job_trigger" "templated" {
  parent       = "projects/example-project"
  display_name = "templated-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/example-project/inspectTemplates/pii-v2"

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

# Inline inspect config
resource "google_data_loss_prevention_job_trigger" "inline_rules" {
  parent       = "projects/example-project"
  display_name = "inline-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_config {
      info_types {
        name = "EMAIL_ADDRESS"
      }
    }

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

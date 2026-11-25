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

# BigQuery trigger with inspection rules, paused: 1 finding
resource "google_data_loss_prevention_job_trigger" "paused_templated" {
  parent       = "projects/example-project"
  display_name = "paused-templated-scan"
  status       = "PAUSED"

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

# No inspection rules, with the BigQuery target built by a dynamic
# storage_config: 1 finding
variable "ruleless_scan_tables" {
  type    = list(string)
  default = ["orders"]
}

resource "google_data_loss_prevention_job_trigger" "ruleless_dynamic_target" {
  parent       = "projects/example-project"
  display_name = "ruleless-dynamic-target-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "storage_config" {
      for_each = var.ruleless_scan_tables

      content {
        big_query_options {
          table_reference {
            project_id = "example-project"
            dataset_id = "analytics_data"
            table_id   = storage_config.value
          }
        }
      }
    }

    actions {
      publish_summary_to_cscc {}
    }
  }
}

# The only inspection rules come from a dynamic inspect_config whose
# for_each is empty, so the trigger has none: 1 finding
resource "google_data_loss_prevention_job_trigger" "ruleless_empty_dynamic" {
  parent       = "projects/example-project"
  display_name = "ruleless-empty-dynamic-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "inspect_config" {
      for_each = []

      content {
        min_likelihood = inspect_config.value
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

# The only inspection rules come from a dynamic inspect_config whose for_each
# is a conditional that selects an empty list, so the trigger has none:
# 1 finding
resource "google_data_loss_prevention_job_trigger" "ruleless_conditional_dynamic" {
  parent       = "projects/example-project"
  display_name = "ruleless-conditional-dynamic-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "inspect_config" {
      for_each = tolist(["["] != [] ? [] : ["]"])

      content {
        info_types {
          name = "EMAIL_ADDRESS"
        }
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

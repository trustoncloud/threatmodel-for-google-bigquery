# Bigquery.C21 (bigquery_dlp_protection) - universal - COMPLIANT

# Managed template reference, explicitly HEALTHY
resource "google_data_loss_prevention_job_trigger" "templated" {
  parent       = "projects/example-project"
  display_name = "templated-scan"
  status       = "HEALTHY"

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

# Inline rules built by a dynamic inspect_config with a literal, non-empty
# for_each
resource "google_data_loss_prevention_job_trigger" "dynamic_rules" {
  parent       = "projects/example-project"
  display_name = "dynamic-rules-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "inspect_config" {
      for_each = ["EMAIL_ADDRESS"]

      content {
        info_types {
          name = inspect_config.value
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

# Inline rules built by a dynamic inspect_config over a literal, non-empty set
resource "google_data_loss_prevention_job_trigger" "dynamic_rules_set" {
  parent       = "projects/example-project"
  display_name = "dynamic-rules-set-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "inspect_config" {
      for_each = toset(["EMAIL_ADDRESS"])

      content {
        info_types {
          name = inspect_config.value
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

# Inline rules built by a dynamic inspect_config over a literal map
resource "google_data_loss_prevention_job_trigger" "dynamic_rules_map" {
  parent       = "projects/example-project"
  display_name = "dynamic-rules-map-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "inspect_config" {
      for_each = tomap({ email = "EMAIL_ADDRESS" })

      content {
        info_types {
          name = inspect_config.value
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

# Inline rules built by a dynamic inspect_config over a literal number list
resource "google_data_loss_prevention_job_trigger" "dynamic_rules_numbers" {
  parent       = "projects/example-project"
  display_name = "dynamic-rules-numbers-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    dynamic "inspect_config" {
      for_each = tolist([1])

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

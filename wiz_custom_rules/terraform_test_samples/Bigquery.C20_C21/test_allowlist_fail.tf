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

# Authorized template overridden by an inline config that drops every
# EMAIL_ADDRESS finding: 1 finding
resource "google_data_loss_prevention_job_trigger" "template_with_override" {
  parent       = "projects/example-project"
  display_name = "override-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1"

    inspect_config {
      min_likelihood = "VERY_LIKELY"

      rule_set {
        info_types {
          name = "EMAIL_ADDRESS"
        }
        rules {
          exclusion_rule {
            regex {
              pattern = ".+"
            }
            matching_type = "MATCHING_TYPE_FULL_MATCH"
          }
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

# Authorized template overridden by an inline config built by a dynamic
# block: 1 finding
variable "override_likelihoods" {
  type = list(string)
}

resource "google_data_loss_prevention_job_trigger" "template_with_dynamic_override" {
  parent       = "projects/example-project"
  display_name = "dynamic-override-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1"

    dynamic "inspect_config" {
      for_each = var.override_likelihoods

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

# Authorized template, paused: 1 finding
resource "google_data_loss_prevention_job_trigger" "paused_trigger" {
  parent       = "projects/example-project"
  display_name = "paused-scan"
  status       = "PAUSED"

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

# Authorized template, cancelled: 1 finding
resource "google_data_loss_prevention_job_trigger" "cancelled_trigger" {
  parent       = "projects/example-project"
  display_name = "cancelled-scan"
  status       = "CANCELLED"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/finance-pci-v1"

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

# Lookalike: the authorized template's name in another project: 1 finding
resource "google_data_loss_prevention_job_trigger" "lookalike_other_project" {
  parent       = "projects/example-project"
  display_name = "other-project-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/attacker-project/inspectTemplates/strict-pii-v1"

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

# Lookalike: a regional template with the authorized template's id. It is a
# different template from the global one: 1 finding
resource "google_data_loss_prevention_job_trigger" "lookalike_other_location" {
  parent       = "projects/example-project/locations/us-central1"
  display_name = "other-location-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/locations/us-central1/inspectTemplates/strict-pii-v1"

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

# Lookalike: the authorized template's id with a suffix: 1 finding
resource "google_data_loss_prevention_job_trigger" "lookalike_suffix" {
  parent       = "projects/example-project"
  display_name = "suffix-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1_2"

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

# Lookalike: a project number where the entry uses the project ID: 1 finding
resource "google_data_loss_prevention_job_trigger" "lookalike_project_number" {
  parent       = "projects/example-project"
  display_name = "project-number-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/123456789012/inspectTemplates/strict-pii-v1"

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

# A template set from a variable with no default is not known until apply:
# 1 finding
variable "scan_template" {
  type = string
}

resource "google_data_loss_prevention_job_trigger" "unresolved_template" {
  parent       = "projects/example-project"
  display_name = "unresolved-template-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = var.scan_template

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

# Authorized template overridden inline, with the BigQuery target built by a
# dynamic storage_config: 1 finding
variable "override_scan_tables" {
  type    = list(string)
  default = ["orders"]
}

resource "google_data_loss_prevention_job_trigger" "override_dynamic_target" {
  parent       = "projects/example-project"
  display_name = "override-dynamic-target-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1"

    inspect_config {
      min_likelihood = "VERY_LIKELY"
    }

    dynamic "storage_config" {
      for_each = var.override_scan_tables

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

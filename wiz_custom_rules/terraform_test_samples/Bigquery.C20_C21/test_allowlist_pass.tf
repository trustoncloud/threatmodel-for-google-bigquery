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

# The authorized template written with its global location, and an explicit
# HEALTHY status
resource "google_data_loss_prevention_job_trigger" "bq_scan_global_form" {
  parent       = "projects/example-project"
  display_name = "bq-pci-scan"
  status       = "HEALTHY"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/locations/global/inspectTemplates/finance-pci-v1"

    storage_config {
      big_query_options {
        table_reference {
          project_id = "example-project"
          dataset_id = "analytics_data"
          table_id   = "payments"
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

# Authorized template with a dynamic inspect_config whose for_each is empty,
# so Terraform builds no override
resource "google_data_loss_prevention_job_trigger" "bq_scan_empty_override" {
  parent       = "projects/example-project"
  display_name = "bq-empty-override-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1"

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
          table_id   = "customers"
        }
      }
    }

    actions {
      publish_summary_to_cscc {}
    }
  }
}

# Authorized template with a dynamic inspect_config over an empty literal set,
# so Terraform builds no override
resource "google_data_loss_prevention_job_trigger" "bq_scan_empty_set_override" {
  parent       = "projects/example-project"
  display_name = "bq-empty-set-override-scan"

  triggers {
    schedule {
      recurrence_period_duration = "86400s"
    }
  }

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/finance-pci-v1"

    dynamic "inspect_config" {
      for_each = toset([])

      content {
        min_likelihood = inspect_config.value
      }
    }

    storage_config {
      big_query_options {
        table_reference {
          project_id = "example-project"
          dataset_id = "analytics_data"
          table_id   = "invoices"
        }
      }
    }

    actions {
      publish_summary_to_cscc {}
    }
  }
}

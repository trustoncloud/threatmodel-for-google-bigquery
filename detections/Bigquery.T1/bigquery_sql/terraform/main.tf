# AUTO-GENERATED. Wraps detect_t1_*.sql as a BigQuery scheduled query
# and routes findings to a Pub/Sub alert topic. Variables are intentionally lean —
# this module is meant to be invoked from a project-level orchestrator.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.20.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us"
}

variable "audit_project" {
  type = string
}

variable "audit_dataset" {
  type = string
}

variable "destination_dataset" {
  type = string
}

variable "destination_table" {
  type    = string
  default = "detections_t1"
}

variable "alert_topic" {
  type = string
}

variable "lookback_seconds" {
  type    = number
  default = 3600
}

variable "schedule" {
  type    = string
  default = "every 15 minutes"
}

locals {
  query_template = file("${path.module}/../detect_t1.sql")
}

resource "google_bigquery_data_transfer_config" "detection" {
  display_name           = "ThreatModel detection: Bigquery.T1"
  location               = var.region
  data_source_id         = "scheduled_query"
  schedule               = var.schedule
  destination_dataset_id = var.destination_dataset

  params = {
    destination_table_name_template = var.destination_table
    write_disposition               = "WRITE_APPEND"
    query                           = replace(replace(local.query_template,
                                          "$${audit_project}", var.audit_project),
                                          "$${audit_dataset}", var.audit_dataset)
  }

  notification_pubsub_topic = var.alert_topic
}

output "transfer_config_name" {
  value = google_bigquery_data_transfer_config.detection.name
}

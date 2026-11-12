# Bigquery.C115 (bigquery_listing_restricted_export) - universal - VIOLATING

# No restricted export at all: 1 finding
resource "google_bigquery_analytics_hub_listing" "open_export" {
  data_exchange_id = "internal_analytics"
  listing_id       = "open_listing"
  display_name     = "Open Listing"
  location         = "us"
  description      = "Exportable"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# Enabled but query results still exportable: 1 finding
resource "google_bigquery_analytics_hub_listing" "partial_export" {
  data_exchange_id = "internal_analytics"
  listing_id       = "partial_listing"
  display_name     = "Partial Listing"
  location         = "us"
  description      = "Partially restricted"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A dataset source built by a dynamic block is still a dataset listing: 1 finding
variable "shared_datasets" {
  type = list(string)
}

resource "google_bigquery_analytics_hub_listing" "generated_source" {
  data_exchange_id = "internal_analytics"
  listing_id       = "generated_listing"
  display_name     = "Generated Listing"
  location         = "us"
  description      = "Source set by a dynamic block"

  dynamic "bigquery_dataset" {
    for_each = var.shared_datasets

    content {
      dataset = bigquery_dataset.value
    }
  }
}

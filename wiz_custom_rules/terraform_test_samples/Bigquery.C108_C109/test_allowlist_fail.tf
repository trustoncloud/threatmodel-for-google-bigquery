# Bigquery.C109 (bigquery_subscription_ingress) - allowlist - VIOLATING

# Subscription to an exchange that is not approved: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "shadow" {
  project          = "vendor-project"
  data_exchange_id = "unknown_marketplace_share"
  listing_id       = "tempting_dataset"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_shadow_data"
      project_id = "my-project"
    }
  }
}

# The approved exchange ID in another project: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "other_project" {
  project          = "vendor-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_vendor_sales"
      project_id = "my-project"
    }
  }
}

# The approved exchange ID in another location: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "other_location" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "europe-west1"

  destination_dataset {
    location = "europe-west1"

    dataset_reference {
      dataset_id = "linked_regional_sales"
      project_id = "my-project"
    }
  }
}

# An exchange with a longer name than the approved one: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "near_name" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange_2"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_second_sales"
      project_id = "my-project"
    }
  }
}

# The project written as a number where the list holds the project ID: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "project_number" {
  project          = "123456789012"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_numbered_sales"
      project_id = "my-project"
    }
  }
}

# Another listing in an exchange where only one listing is approved: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "other_listing" {
  project          = "my-project"
  data_exchange_id = "internal_reference_data"
  listing_id       = "employee_directory"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_directory"
      project_id = "my-project"
    }
  }
}

# No project written in the resource, so the listing cannot be matched: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "no_project" {
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_default_project_sales"
      project_id = "my-project"
    }
  }
}

# A project set from a variable with no default is not known until apply: 1 finding
variable "publisher_project" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_subscription" "variable_project" {
  project          = var.publisher_project
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_variable_sales"
      project_id = "my-project"
    }
  }
}

# A listing set from a variable with no default, in an exchange where only
# one listing is approved: 1 finding
variable "reference_listing" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_subscription" "variable_listing" {
  project          = "my-project"
  data_exchange_id = "internal_reference_data"
  listing_id       = var.reference_listing
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_reference"
      project_id = "my-project"
    }
  }
}

# An approved listing linked into a project that may not subscribe: 1 finding
resource "google_bigquery_analytics_hub_listing_subscription" "other_destination" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_partner_sales"
      project_id = "sandbox-project"
    }
  }
}

# A destination project set from a variable with no default is not known
# until apply: 1 finding
variable "subscriber_project" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_subscription" "variable_destination" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_partner_sales"
      project_id = var.subscriber_project
    }
  }
}

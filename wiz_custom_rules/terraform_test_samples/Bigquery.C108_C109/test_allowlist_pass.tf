# Bigquery.C109 (bigquery_subscription_ingress) - allowlist - COMPLIANT

# A listing in an approved exchange, linked into an approved project
resource "google_bigquery_analytics_hub_listing_subscription" "governed" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "sales_data_shared"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_partner_sales"
      project_id = "my-project"
    }
  }
}

# Location written in upper case names the same exchange
resource "google_bigquery_analytics_hub_listing_subscription" "upper_case_location" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = "inventory_shared"
  location         = "US"

  destination_dataset {
    location = "US"

    dataset_reference {
      dataset_id = "linked_partner_inventory"
      project_id = "my-project"
    }
  }
}

# A single approved listing in an exchange that is not approved as a whole
resource "google_bigquery_analytics_hub_listing_subscription" "reference_listing" {
  project          = "my-project"
  data_exchange_id = "internal_reference_data"
  listing_id       = "public_holidays"
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_public_holidays"
      project_id = "my-project"
    }
  }
}

# A listing set from a variable with no default, in an exchange approved as
# a whole: every listing in it is approved
variable "partner_listing" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_subscription" "any_partner_listing" {
  project          = "partner-project"
  data_exchange_id = "governed_partner_exchange"
  listing_id       = var.partner_listing
  location         = "us"

  destination_dataset {
    location = "us"

    dataset_reference {
      dataset_id = "linked_partner_listing"
      project_id = "my-project"
    }
  }
}

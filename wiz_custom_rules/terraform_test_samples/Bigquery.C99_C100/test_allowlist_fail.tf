# Bigquery.C100 (bigquery_listing_security) - allowlist - VIOLATING

# Public discovery + unrestricted export + missing docs: 4 findings
resource "google_bigquery_analytics_hub_listing" "exposed" {
  data_exchange_id = "internal_analytics"
  listing_id       = "exposed_listing"
  display_name     = "Exposed Listing"
  location         = "us"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A listing that leaves out discovery_type takes it from its exchange. Here
# the exchange is public, named once by reference and once by its ID: 2 findings
resource "google_bigquery_analytics_hub_data_exchange" "marketplace" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "public_marketplace"
  display_name     = "Public Marketplace"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

resource "google_bigquery_analytics_hub_listing" "inherits_public" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.marketplace.data_exchange_id
  listing_id       = "inherits_public"
  display_name     = "Inherits Public"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/inherits-public"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

resource "google_bigquery_analytics_hub_listing" "inherits_public_by_id" {
  project          = "my-project"
  location         = "US"
  data_exchange_id = "public_marketplace"
  listing_id       = "inherits_public_by_id"
  display_name     = "Inherits Public By ID"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/inherits-public-by-id"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A discovery type set from a variable with no default is not known until
# apply, on the listing or on its exchange: 2 findings
variable "listing_discovery" {
  type = string
}

resource "google_bigquery_analytics_hub_listing" "variable_discovery" {
  data_exchange_id = "internal_analytics"
  listing_id       = "zip_codes"
  display_name     = "Variable Discovery"
  location         = "us"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/variable-discovery"
  discovery_type   = var.listing_discovery

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

variable "exchange_discovery" {
  type = string
}

resource "google_bigquery_analytics_hub_data_exchange" "variable_exchange" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "variable_exchange"
  display_name     = "Variable Exchange"
  discovery_type   = var.exchange_discovery
}

resource "google_bigquery_analytics_hub_listing" "under_variable_exchange" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.variable_exchange.data_exchange_id
  listing_id       = "under_variable_exchange"
  display_name     = "Under Variable Exchange"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/under-variable-exchange"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A listing that leaves out discovery_type and names its exchange through a
# variable with no default: the exchange cannot be read: 1 finding
variable "exchange_id" {
  type = string
}

resource "google_bigquery_analytics_hub_listing" "variable_exchange_id" {
  data_exchange_id = var.exchange_id
  listing_id       = "variable_exchange_id"
  display_name     = "Variable Exchange ID"
  location         = "us"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/variable-exchange-id"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A reference gives the exchange ID only, and the listing states the project.
# This listing is in another project, where the exchange with that ID is
# public: 1 finding
resource "google_bigquery_analytics_hub_data_exchange" "private_twin" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "shared_feeds"
  display_name     = "Shared Feeds"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}

resource "google_bigquery_analytics_hub_data_exchange" "public_twin" {
  project          = "partner-project"
  location         = "us"
  data_exchange_id = "shared_feeds"
  display_name     = "Shared Feeds"
  discovery_type   = "DISCOVERY_TYPE_PUBLIC"
}

resource "google_bigquery_analytics_hub_listing" "reference_other_project" {
  project          = "partner-project"
  location         = "us"
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.private_twin.data_exchange_id
  listing_id       = "reference_other_project"
  display_name     = "Reference Other Project"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/reference-other-project"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A listing that states no project cannot be tied to an exchange that states
# one, so its exchange cannot be read: 1 finding
resource "google_bigquery_analytics_hub_listing" "reference_no_project" {
  location         = "us"
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.private_twin.data_exchange_id
  listing_id       = "reference_no_project"
  display_name     = "Reference No Project"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/reference-no-project"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A restricted listing takes its discovery type from its exchange. This
# exchange is declared outside the scanned files and is not listed as
# private: 1 finding
resource "google_bigquery_analytics_hub_listing" "outside_scan_unlisted" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "partner_catalog"
  listing_id       = "outside_scan_unlisted"
  display_name     = "Outside Scan Unlisted"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/outside-scan-unlisted"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# The exchange ID is on the list of private exchanges, but the listing states
# no project, so it cannot be matched to the list: 1 finding
resource "google_bigquery_analytics_hub_listing" "outside_scan_no_project" {
  location         = "us"
  data_exchange_id = "internal_analytics"
  listing_id       = "outside_scan_no_project"
  display_name     = "Outside Scan No Project"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/outside-scan-no-project"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

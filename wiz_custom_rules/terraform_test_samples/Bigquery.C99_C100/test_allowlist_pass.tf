# Bigquery.C100 (bigquery_listing_security) - allowlist - COMPLIANT

# A restricted listing cannot set discovery_type. It takes the one of its
# exchange, here an exchange declared elsewhere and listed as private
resource "google_bigquery_analytics_hub_listing" "governed" {
  project          = "my-project"
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  display_name     = "Governed Listing"
  location         = "us"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/governed-listing"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# Allowlisted exportable reference listing
resource "google_bigquery_analytics_hub_listing" "reference" {
  project          = "my-project"
  data_exchange_id = "internal_analytics"
  listing_id       = "public_holidays"
  display_name     = "Public Holidays"
  location         = "us"
  description      = "Reference calendar data"
  documentation    = "https://wiki.example.com/data/holidays"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/reference_data"
  }
}

# A listing that leaves out discovery_type under a private exchange
resource "google_bigquery_analytics_hub_data_exchange" "internal" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "internal_catalog"
  display_name     = "Internal Catalog"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"
}

resource "google_bigquery_analytics_hub_listing" "inherits_private" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.internal.data_exchange_id
  listing_id       = "inherits_private"
  display_name     = "Inherits Private"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/inherits-private"

  restricted_export_config {
    enabled = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A listing approved for export can state its own discovery type, whatever
# its exchange is
resource "google_bigquery_analytics_hub_listing" "private_by_id" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "internal_catalog"
  listing_id       = "zip_codes"
  display_name     = "Private By ID"
  description      = "Curated order analytics"
  documentation    = "https://wiki.example.com/data/private-by-id"
  discovery_type   = "DISCOVERY_TYPE_PRIVATE"

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A Pub/Sub topic listing shares no dataset, so restricted export does not
# apply to it
resource "google_bigquery_analytics_hub_listing" "topic_feed" {
  project          = "my-project"
  location         = "us"
  data_exchange_id = "internal_catalog"
  listing_id       = "order_events"
  display_name     = "Order Events"
  description      = "Order event stream"
  documentation    = "https://wiki.example.com/data/order-events"

  pubsub_topic {
    topic = "projects/example-project/topics/order-events"
  }
}

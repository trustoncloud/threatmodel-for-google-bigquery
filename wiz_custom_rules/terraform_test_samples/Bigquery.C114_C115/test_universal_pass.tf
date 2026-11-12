# Bigquery.C115 (bigquery_listing_restricted_export) - universal - COMPLIANT

resource "google_bigquery_analytics_hub_listing" "locked_down" {
  data_exchange_id = "internal_analytics"
  listing_id       = "locked_listing"
  display_name     = "Locked Listing"
  location         = "us"
  description      = "View-only sharing"

  restricted_export_config {
    enabled               = true
    restrict_query_result = true
  }

  bigquery_dataset {
    dataset = "projects/example-project/datasets/analytics_data"
  }
}

# A Pub/Sub topic listing shares no dataset, so restricted export does not
# apply to it
resource "google_bigquery_analytics_hub_listing" "topic_feed" {
  data_exchange_id = "internal_analytics"
  listing_id       = "order_events"
  display_name     = "Order Events"
  location         = "us"
  description      = "Order event stream"

  pubsub_topic {
    topic = "projects/example-project/topics/order-events"
  }
}

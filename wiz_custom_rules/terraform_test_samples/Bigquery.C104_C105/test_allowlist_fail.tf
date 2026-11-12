# Bigquery.C105 (bigquery_subscription_governance) - allowlist - VIOLATING

# Public subscriber grant: 1 finding
resource "google_bigquery_analytics_hub_data_exchange_iam_member" "public_grant" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

# Subscriber from an unauthorized domain via a binding: 1 finding
resource "google_bigquery_analytics_hub_listing_iam_binding" "vendor_subscribers" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  role             = "roles/analyticshub.admin"
  members = [
    "group:consumers@yourcompany.com",
    "user:outsider@external-vendor.com"
  ]
}

# Lookalikes of the approved domains, and service accounts from projects that
# are not approved: 7 findings
resource "google_bigquery_analytics_hub_listing_iam_binding" "lookalike_subscribers" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  members = [
    "user:intruder@notyourcompany.com",
    "user:x@yourcompany.com.evil.io",
    "group:team@eng.yourcompany.com",
    "user:a@yourcompany.com@evil.io",
    "serviceAccount:reader@untrusted-project.iam.gserviceaccount.com",
    "serviceAccount:reader@my-project-rogue.iam.gserviceaccount.com",
    "serviceAccount:service-111111111111@attacker-proj.iam.gserviceaccount.com",
  ]
}

# A grant to a whole domain is reported, whether or not the domain is
# approved for its users: 2 findings
resource "google_bigquery_analytics_hub_data_exchange_iam_member" "lookalike_domain" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  member           = "domain:notyourcompany.com"
}

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "whole_domain" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  member           = "domain:yourcompany.com"
}

# A member set from a variable with no default is not known until apply: 1 finding
variable "subscriber" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_iam_member" "variable_member" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  role             = "roles/analyticshub.subscriber"
  member           = var.subscriber
}

# A role set from a variable with no default may be a subscriber role, so
# its member is checked: 1 finding
variable "listing_role" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_iam_member" "variable_role" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  role             = var.listing_role
  member           = "user:outsider@external-vendor.com"
}

# A policy that takes its bindings from a data source in this file, with a
# subscriber who is not approved: 1 finding
data "google_iam_policy" "vendor" {
  binding {
    role = "roles/analyticshub.subscriber"
    members = [
      "group:consumers@yourcompany.com",
      "user:contractor@external-vendor.com",
    ]
  }

  binding {
    role    = "roles/analyticshub.viewer"
    members = ["user:guest@external.com"]
  }
}

resource "google_bigquery_analytics_hub_data_exchange_iam_policy" "vendor_policy" {
  data_exchange_id = "internal_analytics"
  location         = "us"
  policy_data      = data.google_iam_policy.vendor.policy_data
}

# A policy whose bindings are built by a dynamic block cannot be read: 1 finding
variable "listing_bindings" {
  type = list(object({ role = string, members = list(string) }))
}

data "google_iam_policy" "generated" {
  dynamic "binding" {
    for_each = var.listing_bindings

    content {
      role    = binding.value.role
      members = binding.value.members
    }
  }
}

resource "google_bigquery_analytics_hub_listing_iam_policy" "generated_policy" {
  data_exchange_id = "internal_analytics"
  listing_id       = "governed_listing"
  location         = "us"
  policy_data      = data.google_iam_policy.generated.policy_data
}

# A policy passed in as text, from a variable with no default, cannot be
# read: 1 finding
variable "listing_policy_json" {
  type = string
}

resource "google_bigquery_analytics_hub_listing_iam_policy" "passed_in_policy" {
  data_exchange_id = "internal_analytics"
  listing_id       = "reference_listing"
  location         = "us"
  policy_data      = var.listing_policy_json
}

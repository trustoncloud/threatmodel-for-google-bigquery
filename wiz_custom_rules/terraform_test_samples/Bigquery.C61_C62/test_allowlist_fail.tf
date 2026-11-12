# Bigquery.C62 (bigquery_reservation_config) - allowlist - VIOLATING

# Unauthorized edition + oversized capacity + idle-slot sharing: 3 findings
resource "google_bigquery_reservation" "oversized" {
  name              = "oversized-slots"
  location          = "us"
  edition           = "STANDARD"
  slot_capacity     = 5000
  ignore_idle_slots = false
}

# Assignment to an unauthorized assignee: 1 finding
resource "google_bigquery_reservation_assignment" "rogue_assignment" {
  assignee    = "projects/random-sandbox"
  job_type    = "QUERY"
  reservation = google_bigquery_reservation.oversized.id
}

# Baseline within the ceiling, but autoscaling can add slots beyond it: 1 finding
resource "google_bigquery_reservation" "autoscaled_over" {
  name              = "autoscaled-over"
  location          = "us"
  edition           = "ENTERPRISE"
  slot_capacity     = 1000
  ignore_idle_slots = true

  autoscale {
    max_slots = 10000
  }
}

# Autoscaling set from a variable with no default is not known until apply: 1 finding
variable "burst_slots" {
  type = number
}

resource "google_bigquery_reservation" "autoscale_variable" {
  name              = "autoscale-variable"
  location          = "us"
  edition           = "ENTERPRISE"
  slot_capacity     = 500
  ignore_idle_slots = true

  autoscale {
    max_slots = var.burst_slots
  }
}

# An autoscale block built by a dynamic block cannot be read: 1 finding
variable "autoscale_settings" {
  type = list(object({ max_slots = number }))
}

resource "google_bigquery_reservation" "autoscale_dynamic" {
  name              = "autoscale-dynamic"
  location          = "us"
  edition           = "ENTERPRISE"
  slot_capacity     = 500
  ignore_idle_slots = true

  dynamic "autoscale" {
    for_each = var.autoscale_settings

    content {
      max_slots = autoscale.value.max_slots
    }
  }
}

# Approved assignee and job type, sent to a reservation that is neither in
# this scan nor approved: 1 finding
resource "google_bigquery_reservation_assignment" "to_unknown_reservation" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = "projects/vendor-admin-project/locations/us/reservations/vendor-slots"
}

# The approved reservation name in another project, in another location, and
# with a longer name: 3 findings
resource "google_bigquery_reservation_assignment" "lookalike_project" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = "projects/my-admin-project-2/locations/us/reservations/shared-slots"
}

resource "google_bigquery_reservation_assignment" "lookalike_location" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = "projects/my-admin-project/locations/eu/reservations/shared-slots"
}

resource "google_bigquery_reservation_assignment" "lookalike_name" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = "projects/my-admin-project/locations/us/reservations/shared-slots-2"
}

# A bare reservation name with no project and location cannot be matched: 1 finding
resource "google_bigquery_reservation_assignment" "bare_name" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = "shared-slots"
}

# A reservation set from a variable with no default is not known until apply: 1 finding
variable "target_reservation" {
  type = string
}

resource "google_bigquery_reservation_assignment" "variable_reservation" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = var.target_reservation
}

# A reference to a reservation name gives the short name only. These
# assignments sit in another location and another project, so they target
# reservations this scan does not declare: 2 findings
resource "google_bigquery_reservation_assignment" "name_reference_other_location" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  location    = "eu"
  reservation = google_bigquery_reservation.autoscaled_over.name
}

resource "google_bigquery_reservation_assignment" "name_reference_other_project" {
  project     = "vendor-admin-project"
  location    = "us"
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = google_bigquery_reservation.autoscaled_over.name
}

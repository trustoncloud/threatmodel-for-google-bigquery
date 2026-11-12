# Bigquery.C62 (bigquery_reservation_config) - allowlist - COMPLIANT

resource "google_bigquery_reservation" "prod_slots" {
  name              = "prod-slots"
  location          = "us"
  edition           = "ENTERPRISE"
  slot_capacity     = 1000
  ignore_idle_slots = true
}

resource "google_bigquery_reservation_assignment" "prod_assignment" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = google_bigquery_reservation.prod_slots.id
}

# Baseline plus autoscaling stays within the ceiling
resource "google_bigquery_reservation" "autoscaled_within" {
  name              = "autoscaled-within"
  location          = "us"
  edition           = "ENTERPRISE"
  slot_capacity     = 500
  ignore_idle_slots = true

  autoscale {
    max_slots = 1000
  }
}

# Tied to a reservation in this scan by its name attribute
resource "google_bigquery_reservation_assignment" "by_name_reference" {
  assignee    = "folders/123456789"
  job_type    = "PIPELINE"
  location    = "us"
  reservation = google_bigquery_reservation.autoscaled_within.name
}

# An approved reservation outside this scan, written as a full name
resource "google_bigquery_reservation_assignment" "to_approved_reservation" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = "projects/my-admin-project/locations/us/reservations/shared-slots"
}

# The same approved reservation, written as project, location and name
resource "google_bigquery_reservation_assignment" "to_approved_by_parts" {
  project     = "my-admin-project"
  location    = "US"
  assignee    = "projects/my-data-project"
  job_type    = "ML_EXTERNAL"
  reservation = "shared-slots"
}

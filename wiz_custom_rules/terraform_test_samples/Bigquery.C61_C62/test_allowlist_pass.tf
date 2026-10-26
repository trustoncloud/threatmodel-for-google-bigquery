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

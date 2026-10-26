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

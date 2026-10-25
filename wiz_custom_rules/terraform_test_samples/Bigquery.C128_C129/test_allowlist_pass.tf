# Bigquery.C129 (bigquery_gemini_enablement) - allowlist - COMPLIANT

resource "google_project_service" "gemini_authorized" {
  project = "data-science-prod"
  service = "cloudaicompanion.googleapis.com"
}

# Unrelated service enablement: out of scope
resource "google_project_service" "bigquery_api" {
  project = "random-sandbox"
  service = "bigquery.googleapis.com"
}

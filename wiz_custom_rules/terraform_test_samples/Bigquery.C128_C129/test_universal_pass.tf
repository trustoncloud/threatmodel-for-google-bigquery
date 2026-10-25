# Bigquery.C129 (bigquery_gemini_enablement) - universal - COMPLIANT

# No Gemini enablement declared
resource "google_project_service" "bigquery_api" {
  project = "example-project"
  service = "bigquery.googleapis.com"
}

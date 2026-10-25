# Bigquery.C129 (bigquery_gemini_enablement) - universal - VIOLATING

# Gemini enablement declared under a universal ban: 1 finding
resource "google_project_service" "gemini_anywhere" {
  project = "example-project"
  service = "cloudaicompanion.googleapis.com"
}

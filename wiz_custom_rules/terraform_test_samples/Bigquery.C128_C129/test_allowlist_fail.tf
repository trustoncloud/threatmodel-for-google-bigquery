# Bigquery.C129 (bigquery_gemini_enablement) - allowlist - VIOLATING

# Gemini enabled on an unauthorized project: 1 finding
resource "google_project_service" "shadow_gemini" {
  project = "random-sandbox"
  service = "cloudaicompanion.googleapis.com"
}

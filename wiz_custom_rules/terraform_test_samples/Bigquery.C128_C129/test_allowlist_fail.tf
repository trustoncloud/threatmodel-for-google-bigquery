# Bigquery.C129 (bigquery_gemini_enablement) - allowlist - VIOLATING

# Gemini enabled on an unauthorized project: 1 finding
resource "google_project_service" "shadow_gemini" {
  project = "random-sandbox"
  service = "cloudaicompanion.googleapis.com"
}

# A project ID that only contains an approved ID is another project: 2 findings
resource "google_project_service" "lookalike_suffix" {
  project = "data-science-prod-rogue"
  service = "cloudaicompanion.googleapis.com"
}

resource "google_project_service" "lookalike_prefix" {
  project = "xinnovation-lab"
  service = "cloudaicompanion.googleapis.com"
}

# No project: the provider default is not in the source: 1 finding
resource "google_project_service" "no_project" {
  service = "cloudaicompanion.googleapis.com"
}

# A project set from a variable with no default is not known until apply: 1 finding
variable "gemini_project" {
  type = string
}

resource "google_project_service" "variable_project" {
  project = var.gemini_project
  service = "cloudaicompanion.googleapis.com"
}

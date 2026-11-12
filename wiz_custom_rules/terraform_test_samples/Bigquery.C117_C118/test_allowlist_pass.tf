# Bigquery.C118 (bigquery_dataset_access_governance) - allowlist - COMPLIANT

# Mandatory admin granted inline
resource "google_bigquery_dataset" "inline_admin" {
  dataset_id = "inline_admin_data"
  location   = "US"

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  access {
    role          = "READER"
    user_by_email = "analyst@yourcompany.com"
  }
}

# Mandatory admin granted through the standalone resource
resource "google_bigquery_dataset" "standalone_admin" {
  dataset_id = "standalone_admin_data"
  location   = "US"
}

resource "google_bigquery_dataset_access" "admin_grant" {
  dataset_id     = google_bigquery_dataset.standalone_admin.dataset_id
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

# A service account from an approved project
resource "google_bigquery_dataset_access" "loader_grant" {
  dataset_id    = google_bigquery_dataset.standalone_admin.dataset_id
  role          = "WRITER"
  user_by_email = "etl-loader@my-project.iam.gserviceaccount.com"
}

# Mandatory admin granted through google_bigquery_dataset_iam_member
resource "google_bigquery_dataset" "iam_member_admin" {
  dataset_id = "iam_member_admin_data"
  location   = "US"
}

resource "google_bigquery_dataset_iam_member" "admin_member" {
  dataset_id = google_bigquery_dataset.iam_member_admin.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "group:data-admins@yourcompany.com"
}

# Mandatory admin granted through google_bigquery_dataset_iam_binding
resource "google_bigquery_dataset" "iam_binding_admin" {
  project    = "analytics-prod"
  dataset_id = "iam_binding_admin_data"
  location   = "US"
}

resource "google_bigquery_dataset_iam_binding" "admin_binding" {
  project    = "analytics-prod"
  dataset_id = "iam_binding_admin_data"
  role       = "roles/bigquery.dataOwner"

  members = [
    "group:data-admins@yourcompany.com",
  ]
}

# Mandatory admin granted through google_bigquery_dataset_iam_policy
resource "google_bigquery_dataset" "iam_policy_admin" {
  dataset_id = "iam_policy_admin_data"
  location   = "US"
}

data "google_iam_policy" "admin_policy" {
  binding {
    role = "roles/bigquery.dataOwner"

    members = [
      "group:data-admins@yourcompany.com",
    ]
  }

  binding {
    role = "roles/bigquery.dataViewer"

    members = [
      "group:analysts@subsidiary.com",
      "serviceAccount:reporting@my-project.iam.gserviceaccount.com",
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "admin_policy" {
  dataset_id  = google_bigquery_dataset.iam_policy_admin.dataset_id
  policy_data = data.google_iam_policy.admin_policy.policy_data
}

# Dataset and admin grant under the same provider configuration
provider "google" {
  alias   = "other"
  project = "other-project"
}

resource "google_bigquery_dataset" "other_provider_data" {
  provider   = google.other
  dataset_id = "other_provider_data"
  location   = "US"
}

resource "google_bigquery_dataset_access" "other_provider_admin" {
  provider       = google.other
  dataset_id     = "other_provider_data"
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

# The dataset leaves provider out and the admin grant names the default
# provider: both use the same configuration
resource "google_bigquery_dataset" "implicit_provider_data" {
  dataset_id = "implicit_provider_data"
  location   = "US"
}

resource "google_bigquery_dataset_access" "explicit_default_provider_admin" {
  provider       = google
  dataset_id     = "implicit_provider_data"
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

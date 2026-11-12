# Bigquery.C8 (bigquery_authorized_access) - allowlist - COMPLIANT

resource "google_bigquery_dataset" "governed" {
  dataset_id = "governed_data"
  location   = "US"

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  access {
    role           = "WRITER"
    group_by_email = "data-team@yourcompany.com"
  }
}

resource "google_bigquery_dataset_access" "admin_reader" {
  dataset_id    = google_bigquery_dataset.governed.dataset_id
  role          = "READER"
  user_by_email = "admin@yourcompany.com"
}

# Table and dataset IAM grants to authorized members, in every form
resource "google_bigquery_table_iam_member" "table_team_member" {
  dataset_id = google_bigquery_dataset.governed.dataset_id
  table_id   = "orders"
  role       = "roles/bigquery.dataViewer"
  member     = "group:data-team@yourcompany.com"
}

resource "google_bigquery_table_iam_binding" "table_admin_binding" {
  dataset_id = google_bigquery_dataset.governed.dataset_id
  table_id   = "orders"
  role       = "roles/bigquery.dataEditor"

  members = [
    "group:data-admins@yourcompany.com",
    "serviceAccount:etl-loader@my-project.iam.gserviceaccount.com",
  ]
}

data "google_iam_policy" "governed_policy" {
  binding {
    role = "roles/bigquery.dataViewer"

    members = [
      "group:data-team@yourcompany.com",
      "user:admin@yourcompany.com",
    ]
  }
}

resource "google_bigquery_table_iam_policy" "table_governed_policy" {
  dataset_id  = google_bigquery_dataset.governed.dataset_id
  table_id    = "orders_view"
  policy_data = data.google_iam_policy.governed_policy.policy_data
}

resource "google_bigquery_dataset_iam_member" "dataset_team_member" {
  dataset_id = google_bigquery_dataset.governed.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:data-team@yourcompany.com"
}

resource "google_bigquery_dataset_iam_binding" "dataset_admin_binding" {
  dataset_id = google_bigquery_dataset.governed.dataset_id
  role       = "roles/bigquery.dataOwner"

  members = [
    "group:data-admins@yourcompany.com",
  ]
}

resource "google_bigquery_dataset_iam_policy" "dataset_governed_policy" {
  dataset_id  = "second_governed_data"
  policy_data = data.google_iam_policy.governed_policy.policy_data
}

# An authorized view, routine and dataset, each written with its project,
# dataset and ID
resource "google_bigquery_dataset_access" "approved_view" {
  dataset_id = google_bigquery_dataset.governed.dataset_id

  view {
    project_id = "my-project"
    dataset_id = "reporting"
    table_id   = "sales_summary"
  }
}

resource "google_bigquery_dataset_access" "approved_routine" {
  dataset_id = google_bigquery_dataset.governed.dataset_id

  routine {
    project_id = "my-project"
    dataset_id = "reporting"
    routine_id = "mask_email"
  }
}

resource "google_bigquery_dataset_access" "approved_dataset" {
  dataset_id = google_bigquery_dataset.governed.dataset_id

  dataset {
    dataset {
      project_id = "my-project"
      dataset_id = "reporting"
    }
    target_types = ["VIEWS"]
  }
}

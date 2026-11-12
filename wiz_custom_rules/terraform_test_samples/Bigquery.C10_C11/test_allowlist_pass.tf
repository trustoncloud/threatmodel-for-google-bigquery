# Bigquery.C11 (bigquery_policy_tag_iam) - allowlist - COMPLIANT

resource "google_data_catalog_policy_tag_iam_member" "reader" {
  policy_tag = "projects/example-project/locations/us/taxonomies/12345/policyTags/67890"
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = "group:sensitive-data-readers@example.com"
}

resource "google_data_catalog_policy_tag_iam_binding" "admins" {
  policy_tag = "projects/example-project/locations/us/taxonomies/12345/policyTags/67890"
  role       = "roles/datacatalog.categoryAdmin"
  members = [
    "user:ciso@example.com"
  ]
}

# Taxonomy grants to authorized entities
resource "google_data_catalog_taxonomy_iam_member" "taxonomy_reader" {
  taxonomy = "projects/example-project/locations/us/taxonomies/12345"
  role     = "roles/datacatalog.categoryFineGrainedReader"
  member   = "group:sensitive-data-readers@example.com"
}

data "google_iam_policy" "approved_readers" {
  binding {
    role = "roles/datacatalog.categoryFineGrainedReader"

    members = [
      "group:sensitive-data-readers@example.com",
      "serviceAccount:etl-pipeline@project-id.iam.gserviceaccount.com"
    ]
  }
}

resource "google_data_catalog_taxonomy_iam_policy" "taxonomy_approved_policy" {
  taxonomy    = "projects/example-project/locations/us/taxonomies/12345"
  policy_data = data.google_iam_policy.approved_readers.policy_data
}

# The Fine-Grained Reader role on the project, to an authorized entity
resource "google_project_iam_member" "project_reader" {
  project = "example-project"
  role    = "roles/datacatalog.categoryFineGrainedReader"
  member  = "user:ciso@example.com"
}

# Other roles on the project, folder or organization are out of scope
resource "google_project_iam_member" "project_viewer" {
  project = "example-project"
  role    = "roles/viewer"
  member  = "group:everyone@example.com"
}

resource "google_folder_iam_binding" "folder_viewers" {
  folder = "folders/123456789012"
  role   = "roles/bigquery.dataViewer"
  members = [
    "group:everyone@example.com"
  ]
}

data "google_iam_policy" "project_policy" {
  binding {
    role    = "roles/viewer"
    members = ["group:everyone@example.com"]
  }

  binding {
    role    = "roles/datacatalog.categoryFineGrainedReader"
    members = ["group:sensitive-data-readers@example.com"]
  }
}

resource "google_project_iam_policy" "project_approved_policy" {
  project     = "example-project"
  policy_data = data.google_iam_policy.project_policy.policy_data
}

# On a project only a grant that names the Fine-Grained Reader role is read. A role
# set from a variable, and a policy whose bindings the source does not show,
# are out of scope
variable "reader_role" {
  type = string
}

resource "google_project_iam_member" "variable_role" {
  project = "example-project"
  role    = var.reader_role
  member  = "user:intern@example.com"
}

variable "project_policy_json" {
  type = string
}

resource "google_project_iam_policy" "unreadable_project_policy" {
  project     = "example-project"
  policy_data = var.project_policy_json
}

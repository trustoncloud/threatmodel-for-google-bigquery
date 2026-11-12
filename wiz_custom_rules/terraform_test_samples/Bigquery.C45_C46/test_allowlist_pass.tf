# Bigquery.C46 (bigquery_data_policy_iam) - allowlist - COMPLIANT

resource "google_bigquery_datapolicy_data_policy_iam_member" "masked_reader" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  member         = "serviceAccount:masked-reader@my-project.iam.gserviceaccount.com"
}

resource "google_bigquery_datapolicy_data_policy_iam_binding" "scientists" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  members = [
    "group:data-scientists@example.com"
  ]
}

# A policy written through a google_iam_policy data source, with authorized
# members only
data "google_iam_policy" "approved_readers" {
  binding {
    role = "roles/bigquerydatapolicy.maskedReader"

    members = [
      "user:admin@example.com",
      "domain:example.com"
    ]
  }
}

resource "google_bigquery_datapolicy_data_policy_iam_policy" "approved_policy" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  policy_data    = data.google_iam_policy.approved_readers.policy_data
}

# The Masked Reader role on the project, to an authorized member
resource "google_project_iam_member" "project_reader" {
  project = "my-project"
  role    = "roles/bigquerydatapolicy.maskedReader"
  member  = "group:data-scientists@example.com"
}

# Other roles on the project, folder or organization are out of scope
resource "google_project_iam_member" "project_viewer" {
  project = "my-project"
  role    = "roles/viewer"
  member  = "group:everyone@external-vendor.com"
}

resource "google_organization_iam_binding" "org_viewers" {
  org_id = "123456789012"
  role   = "roles/bigquery.dataViewer"
  members = [
    "group:everyone@external-vendor.com"
  ]
}

data "google_iam_policy" "project_policy" {
  binding {
    role    = "roles/viewer"
    members = ["group:everyone@external-vendor.com"]
  }

  binding {
    role    = "roles/bigquerydatapolicy.maskedReader"
    members = ["serviceAccount:masked-reader@my-project.iam.gserviceaccount.com"]
  }
}

resource "google_project_iam_policy" "project_approved_policy" {
  project     = "my-project"
  policy_data = data.google_iam_policy.project_policy.policy_data
}

# On a project only a grant that names the Masked Reader role is read. A role
# set from a variable, and a policy whose bindings the source does not show,
# are out of scope
variable "reader_role" {
  type = string
}

resource "google_project_iam_member" "variable_role" {
  project = "my-project"
  role    = var.reader_role
  member  = "user:contractor@external-vendor.com"
}

variable "project_policy_json" {
  type = string
}

resource "google_project_iam_policy" "unreadable_project_policy" {
  project     = "my-project"
  policy_data = var.project_policy_json
}

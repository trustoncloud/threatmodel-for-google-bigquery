# Bigquery.C46 (bigquery_data_policy_iam) - allowlist - VIOLATING

# Unauthorized member on a masking policy: 1 finding
resource "google_bigquery_datapolicy_data_policy_iam_member" "contractor" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  member         = "user:contractor@external-vendor.com"
}

# Binding with an authorized group and an address that only starts like it:
# 1 finding
resource "google_bigquery_datapolicy_data_policy_iam_binding" "mixed" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  members = [
    "group:data-scientists@example.com",
    "group:data-scientists@example.com.evil.io"
  ]
}

# A policy written through a google_iam_policy data source: 1 finding
data "google_iam_policy" "vendor_readers" {
  binding {
    role = "roles/bigquerydatapolicy.maskedReader"

    members = [
      "user:admin@example.com",
      "user:analyst@external-vendor.com"
    ]
  }
}

resource "google_bigquery_datapolicy_data_policy_iam_policy" "vendor_policy" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  policy_data    = data.google_iam_policy.vendor_readers.policy_data
}

# The Masked Reader role on a project, folder or organization reaches every
# data policy below it: 3 findings
resource "google_project_iam_member" "project_reader" {
  project = "my-project"
  role    = "roles/bigquerydatapolicy.maskedReader"
  member  = "user:contractor@external-vendor.com"
}

resource "google_folder_iam_binding" "folder_readers" {
  folder = "folders/123456789012"
  role   = "roles/bigquerydatapolicy.maskedReader"
  members = [
    "group:data-scientists@example.com",
    "group:everyone@external-vendor.com"
  ]
}

resource "google_organization_iam_member" "org_reader" {
  org_id = "123456789012"
  role   = "roles/bigquerydatapolicy.maskedReader"
  member = "domain:external-vendor.com"
}

# A project policy whose data source grants the Masked Reader role to a
# member that is not authorized: 1 finding
data "google_iam_policy" "project_policy" {
  binding {
    role    = "roles/viewer"
    members = ["group:everyone@external-vendor.com"]
  }

  binding {
    role    = "roles/bigquerydatapolicy.maskedReader"
    members = ["serviceAccount:masked-reader@my-project-rogue.iam.gserviceaccount.com"]
  }
}

resource "google_project_iam_policy" "project_vendor_policy" {
  project     = "my-project"
  policy_data = data.google_iam_policy.project_policy.policy_data
}

# A member set from a variable with no default is not known until apply: 1 finding
variable "reader_member" {
  type = string
}

resource "google_project_iam_member" "variable_member" {
  project = "my-project"
  role    = "roles/bigquerydatapolicy.maskedReader"
  member  = var.reader_member
}

# Bindings built with a dynamic block are not in the source as text, so the
# members this policy grants cannot be read: 1 finding
variable "policy_bindings" {
  type = list(object({ role = string, members = list(string) }))
}

data "google_iam_policy" "dynamic_policy" {
  dynamic "binding" {
    for_each = var.policy_bindings

    content {
      role    = binding.value.role
      members = binding.value.members
    }
  }
}

resource "google_bigquery_datapolicy_data_policy_iam_policy" "dynamic_policy" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  policy_data    = data.google_iam_policy.dynamic_policy.policy_data
}

# Bigquery.C118 (bigquery_dataset_access_governance) - allowlist - VIOLATING

# Public access + external domain + missing mandatory admin: 3 findings
resource "google_bigquery_dataset" "exposed" {
  dataset_id = "exposed_data"
  location   = "US"

  access {
    role          = "READER"
    special_group = "allAuthenticatedUsers"
  }

  access {
    role          = "READER"
    user_by_email = "contractor@external-vendor.com"
  }
}

# Standalone grant to an unauthorized domain: 1 finding
resource "google_bigquery_dataset_access" "vendor_grant" {
  dataset_id    = google_bigquery_dataset.exposed.dataset_id
  role          = "WRITER"
  user_by_email = "someone@badvendor.com"
}

# Lookalikes of the approved domains and service accounts from projects that
# are not approved: 6 findings
resource "google_bigquery_dataset" "lookalikes" {
  dataset_id = "lookalike_data"
  location   = "US"

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  access {
    role          = "READER"
    user_by_email = "intruder@notyourcompany.com"
  }

  access {
    role          = "READER"
    user_by_email = "x@eng.yourcompany.com"
  }

  access {
    role   = "READER"
    domain = "notyourcompany.com"
  }

  access {
    role          = "READER"
    user_by_email = "reader@untrusted-project.iam.gserviceaccount.com"
  }

  access {
    role       = "READER"
    iam_member = "serviceAccount:reader@my-project-rogue.iam.gserviceaccount.com"
  }

  access {
    role          = "WRITER"
    user_by_email = "service-111111111111@attacker-proj.iam.gserviceaccount.com"
  }
}

# The admin grant names sales_archive, so sales has no admin: 1 finding
resource "google_bigquery_dataset" "sales" {
  dataset_id = "sales"
  location   = "US"
}

resource "google_bigquery_dataset" "sales_archive" {
  dataset_id = "sales_archive"
  location   = "US"
}

resource "google_bigquery_dataset_access" "sales_archive_admin" {
  dataset_id     = google_bigquery_dataset.sales_archive.dataset_id
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

# The admin grant is for the same dataset ID in another project: 1 finding
resource "google_bigquery_dataset" "finance" {
  project    = "finance-prod"
  dataset_id = "ledger"
  location   = "US"
}

resource "google_bigquery_dataset_access" "ledger_admin_other_project" {
  project        = "finance-dev"
  dataset_id     = "ledger"
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

# Grants made through the dataset IAM resources: 4 findings, and the
# unreadable policy leaves sales_archive's members unknown: 1 finding
resource "google_bigquery_dataset_iam_member" "vendor_member" {
  dataset_id = google_bigquery_dataset.sales_archive.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "user:someone@badvendor.com"
}

resource "google_bigquery_dataset_iam_binding" "mixed_binding" {
  dataset_id = google_bigquery_dataset.sales_archive.dataset_id
  role       = "roles/bigquery.dataEditor"

  members = [
    "group:analysts@yourcompany.com",
    "serviceAccount:loader@untrusted-project.iam.gserviceaccount.com",
    "allUsers",
  ]
}

data "google_iam_policy" "vendor_policy" {
  binding {
    role = "roles/bigquery.dataViewer"

    members = [
      "group:partners@yourcompany.com.evil.io",
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "vendor_policy" {
  dataset_id  = google_bigquery_dataset.sales.dataset_id
  policy_data = data.google_iam_policy.vendor_policy.policy_data
}

resource "google_bigquery_dataset_iam_policy" "unreadable_policy" {
  dataset_id  = google_bigquery_dataset.sales_archive.dataset_id
  policy_data = jsonencode({ bindings = [{ role = "roles/bigquery.dataViewer", members = ["allUsers"] }] })
}

# The admin grant uses another provider configuration than the dataset with
# the same ID, so it can be for another project: 1 finding
provider "google" {
  alias   = "other"
  project = "other-project"
}

resource "google_bigquery_dataset" "other_provider_data" {
  provider   = google.other
  dataset_id = "shared_name_data"
  location   = "US"
}

resource "google_bigquery_dataset_access" "default_provider_admin" {
  dataset_id     = "shared_name_data"
  role           = "OWNER"
  group_by_email = "data-admins@yourcompany.com"
}

# Bindings built with a dynamic block are not in the source as text, so the
# members this policy grants cannot be read: 1 finding
variable "dataset_bindings" {
  type    = list(object({ role = string, members = list(string) }))
  default = []
}

data "google_iam_policy" "dynamic_policy" {
  dynamic "binding" {
    for_each = var.dataset_bindings

    content {
      role    = binding.value.role
      members = binding.value.members
    }
  }
}

resource "google_bigquery_dataset_iam_policy" "dynamic_policy" {
  dataset_id  = google_bigquery_dataset.sales_archive.dataset_id
  policy_data = data.google_iam_policy.dynamic_policy.policy_data
}

# The admin grant holds only while its condition does, so the dataset has no
# standing admin: 1 finding
resource "google_bigquery_dataset" "conditional_admin" {
  dataset_id = "conditional_admin_data"
  location   = "US"
}

resource "google_bigquery_dataset_iam_member" "conditional_admin" {
  dataset_id = google_bigquery_dataset.conditional_admin.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "group:data-admins@yourcompany.com"

  condition {
    title       = "expired"
    description = "Owner access until the end of 2020"
    expression  = "request.time < timestamp(\"2020-01-01T00:00:00Z\")"
  }
}

# The condition on the admin grant is built with a dynamic block, so the
# source does not show whether the grant is unconditional: 1 finding
variable "admin_conditions" {
  type    = list(object({ title = string, expression = string }))
  default = []
}

resource "google_bigquery_dataset" "dynamic_condition_admin" {
  dataset_id = "dynamic_condition_admin_data"
  location   = "US"
}

resource "google_bigquery_dataset_iam_member" "dynamic_condition_admin" {
  dataset_id = google_bigquery_dataset.dynamic_condition_admin.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "group:data-admins@yourcompany.com"

  dynamic "condition" {
    for_each = var.admin_conditions

    content {
      title      = condition.value.title
      expression = condition.value.expression
    }
  }
}

# Access entries built with a dynamic block are not in the source as text,
# so the members they grant cannot be checked: 1 finding
variable "extra_access" {
  type = list(object({ role = string, group = string }))
}

resource "google_bigquery_dataset" "dynamic_access" {
  dataset_id = "dynamic_access_data"
  location   = "US"

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  dynamic "access" {
    for_each = var.extra_access

    content {
      role           = access.value.role
      group_by_email = access.value.group
    }
  }
}

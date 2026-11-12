# Bigquery.C8 (bigquery_authorized_access) - allowlist - VIOLATING

# Inline entry granting an unauthorized user: 1 finding
resource "google_bigquery_dataset" "leaky" {
  dataset_id = "leaky_data"
  location   = "US"

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    user_by_email = "someone@external-vendor.com"
  }
}

# Standalone grant to an unauthorized routine: 1 finding
resource "google_bigquery_dataset_access" "rogue_routine" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id

  routine {
    project_id = "rogue-proj"
    dataset_id = "rogue_ds"
    routine_id = "exfil_udf"
  }
}

# Table and view IAM grants to members that are not authorized: 5 findings
resource "google_bigquery_table_iam_member" "table_vendor_member" {
  dataset_id = "leaky_data"
  table_id   = "orders"
  role       = "roles/bigquery.dataViewer"
  member     = "user:someone@external-vendor.com"
}

resource "google_bigquery_table_iam_binding" "table_mixed_binding" {
  dataset_id = "leaky_data"
  table_id   = "orders"
  role       = "roles/bigquery.dataEditor"

  members = [
    "group:data-team@yourcompany.com",
    "group:data-team@yourcompany.com.evil.io",
    "serviceAccount:etl-loader@my-project-rogue.iam.gserviceaccount.com",
    "allAuthenticatedUsers",
  ]
}

data "google_iam_policy" "table_policy" {
  binding {
    role = "roles/bigquery.dataViewer"

    members = [
      "group:data-admins@yourcompany.com",
      "user:admin@notyourcompany.com",
    ]
  }
}

resource "google_bigquery_table_iam_policy" "table_vendor_policy" {
  dataset_id  = "leaky_data"
  table_id    = "orders_view"
  policy_data = data.google_iam_policy.table_policy.policy_data
}

# Dataset IAM grants to members that are not authorized: 3 findings
resource "google_bigquery_dataset_iam_member" "dataset_vendor_member" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "domain:external-vendor.com"
}

resource "google_bigquery_dataset_iam_binding" "dataset_vendor_binding" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id
  role       = "roles/bigquery.dataEditor"

  members = [
    "user:admin@yourcompany.com",
    "user:contractor@external-vendor.com",
  ]
}

data "google_iam_policy" "dataset_policy" {
  binding {
    role = "roles/bigquery.dataOwner"

    members = [
      "group:data-admins@yourcompany.com",
      "allUsers",
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "dataset_vendor_policy" {
  dataset_id  = google_bigquery_dataset.leaky.dataset_id
  policy_data = data.google_iam_policy.dataset_policy.policy_data
}

# A policy that is not built in a google_iam_policy data source cannot be
# read: 1 finding
resource "google_bigquery_table_iam_policy" "table_unreadable_policy" {
  dataset_id  = "leaky_data"
  table_id    = "customers"
  policy_data = jsonencode({ bindings = [{ role = "roles/bigquery.dataViewer", members = ["allUsers"] }] })
}

# Bindings built with a dynamic block are not in the source as text, so the
# members this policy grants cannot be read: 1 finding
variable "table_bindings" {
  type    = list(object({ role = string, members = list(string) }))
  default = []
}

data "google_iam_policy" "dynamic_policy" {
  dynamic "binding" {
    for_each = var.table_bindings

    content {
      role    = binding.value.role
      members = binding.value.members
    }
  }
}

resource "google_bigquery_table_iam_policy" "table_dynamic_policy" {
  dataset_id  = "analytics_data"
  table_id    = "orders"
  policy_data = data.google_iam_policy.dynamic_policy.policy_data
}

# Authorized views, routines and datasets are matched on project, dataset
# and ID together. The approved view ID in another project and in a dataset
# with a longer name: 2 findings
resource "google_bigquery_dataset" "shared_views" {
  dataset_id = "shared_views_data"
  location   = "US"

  access {
    view {
      project_id = "vendor-project"
      dataset_id = "reporting"
      table_id   = "sales_summary"
    }
  }

  access {
    view {
      project_id = "my-project"
      dataset_id = "reporting_2"
      table_id   = "sales_summary"
    }
  }
}

# The approved routine ID in another dataset: 1 finding
resource "google_bigquery_dataset_access" "lookalike_routine" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id

  routine {
    project_id = "my-project"
    dataset_id = "scratch"
    routine_id = "mask_email"
  }
}

# The approved dataset ID in another project: 1 finding
resource "google_bigquery_dataset_access" "lookalike_dataset" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id

  dataset {
    dataset {
      project_id = "vendor-project"
      dataset_id = "reporting"
    }
    target_types = ["VIEWS"]
  }
}

# A view whose table comes from a variable with no default is not known
# until apply: 1 finding
variable "view_table" {
  type = string
}

resource "google_bigquery_dataset_access" "variable_view" {
  dataset_id = google_bigquery_dataset.leaky.dataset_id

  view {
    project_id = "my-project"
    dataset_id = "reporting"
    table_id   = var.view_table
  }
}

# Access entries built with a dynamic block cannot be read: 1 finding
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

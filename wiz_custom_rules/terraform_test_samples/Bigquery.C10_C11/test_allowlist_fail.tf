# Bigquery.C11 (bigquery_policy_tag_iam) - allowlist - VIOLATING

# Unauthorized reader on a sensitive-column policy tag: 1 finding
resource "google_data_catalog_policy_tag_iam_member" "intern_reader" {
  policy_tag = "projects/example-project/locations/us/taxonomies/12345/policyTags/67890"
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = "user:intern@example.com"
}

# Binding mixing authorized and unauthorized members: 1 finding
resource "google_data_catalog_policy_tag_iam_binding" "mixed" {
  policy_tag = "projects/example-project/locations/us/taxonomies/12345/policyTags/67890"
  role       = "roles/datacatalog.categoryFineGrainedReader"
  members = [
    "group:sensitive-data-readers@example.com",
    "group:everyone@example.com"
  ]
}

# A grant on the taxonomy reaches every policy tag in it: 1 finding
resource "google_data_catalog_taxonomy_iam_member" "taxonomy_intern" {
  taxonomy = "projects/example-project/locations/us/taxonomies/12345"
  role     = "roles/datacatalog.categoryFineGrainedReader"
  member   = "user:intern@example.com"
}

# Taxonomy binding with an authorized group and an address that only starts
# like it: 1 finding
resource "google_data_catalog_taxonomy_iam_binding" "taxonomy_mixed" {
  taxonomy = "projects/example-project/locations/us/taxonomies/12345"
  role     = "roles/datacatalog.categoryFineGrainedReader"
  members = [
    "group:sensitive-data-readers@example.com",
    "group:sensitive-data-readers@example.com.evil.io"
  ]
}

# Policies written through a google_iam_policy data source, on a policy tag
# and on a taxonomy: 2 findings
data "google_iam_policy" "vendor_readers" {
  binding {
    role = "roles/datacatalog.categoryFineGrainedReader"

    members = [
      "user:ciso@example.com",
      "user:analyst@external-vendor.com"
    ]
  }
}

resource "google_data_catalog_policy_tag_iam_policy" "tag_vendor_policy" {
  policy_tag  = "projects/example-project/locations/us/taxonomies/12345/policyTags/67890"
  policy_data = data.google_iam_policy.vendor_readers.policy_data
}

resource "google_data_catalog_taxonomy_iam_policy" "taxonomy_vendor_policy" {
  taxonomy    = "projects/example-project/locations/us/taxonomies/12345"
  policy_data = data.google_iam_policy.vendor_readers.policy_data
}

# The Fine-Grained Reader role on a project, folder or organization reaches
# every policy tag below it: 3 findings
resource "google_project_iam_member" "project_reader" {
  project = "example-project"
  role    = "roles/datacatalog.categoryFineGrainedReader"
  member  = "user:intern@example.com"
}

resource "google_folder_iam_binding" "folder_readers" {
  folder = "folders/123456789012"
  role   = "roles/datacatalog.categoryFineGrainedReader"
  members = [
    "group:sensitive-data-readers@example.com",
    "group:everyone@example.com"
  ]
}

resource "google_organization_iam_member" "org_reader" {
  org_id = "123456789012"
  role   = "roles/datacatalog.categoryFineGrainedReader"
  member = "domain:example.com"
}

# A project policy whose data source grants the reader role to an entity
# that is not authorized: 1 finding
data "google_iam_policy" "project_policy" {
  binding {
    role    = "roles/viewer"
    members = ["group:everyone@example.com"]
  }

  binding {
    role    = "roles/datacatalog.categoryFineGrainedReader"
    members = ["user:contractor@external-vendor.com"]
  }
}

resource "google_project_iam_policy" "project_vendor_policy" {
  project     = "example-project"
  policy_data = data.google_iam_policy.project_policy.policy_data
}

# A member set from a variable with no default is not known until apply: 1 finding
variable "reader_member" {
  type = string
}

resource "google_project_iam_member" "variable_member" {
  project = "example-project"
  role    = "roles/datacatalog.categoryFineGrainedReader"
  member  = var.reader_member
}

# A policy that is not built in a google_iam_policy data source cannot be
# read: 1 finding
variable "tag_policy_json" {
  type = string
}

resource "google_data_catalog_policy_tag_iam_policy" "tag_unreadable_policy" {
  policy_tag  = "projects/example-project/locations/us/taxonomies/12345/policyTags/67890"
  policy_data = var.tag_policy_json
}

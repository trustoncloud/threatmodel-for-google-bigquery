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

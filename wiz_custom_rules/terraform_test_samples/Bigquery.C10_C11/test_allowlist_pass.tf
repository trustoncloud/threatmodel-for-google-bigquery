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

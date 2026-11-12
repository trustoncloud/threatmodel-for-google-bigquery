Grant roles on policy tags and taxonomies only to principals listed in `authorized_principals`, or, once a principal is approved, add it to that list in the rule's configuration:

```hcl
resource "google_data_catalog_policy_tag_iam_member" "example" {
  member = "group:sensitive-data-readers@example.com"
}

resource "google_project_iam_member" "example" {
  role   = "roles/datacatalog.categoryFineGrainedReader"
  member = "group:sensitive-data-readers@example.com"
}
```

The rule reads the member, binding and policy resources for policy tags (`google_data_catalog_policy_tag_iam_*`) and for taxonomies (`google_data_catalog_taxonomy_iam_*`), where any role is in scope. The Fine-Grained Reader role (`roles/datacatalog.categoryFineGrainedReader`) granted on a project, folder or organization reaches every policy tag below it, so the rule applies the same list to that role in `google_project_iam_*`, `google_folder_iam_*` and `google_organization_iam_*`. Other roles granted there are out of scope. Principals are compared exactly as written, prefix included.

Limits of a source scan:

- A member set from a variable or another resource is not known until apply, so it is reported. Write the member in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- On a project, folder or organization only a grant that names the Fine-Grained Reader role is read. A grant there whose role is set from a variable or another resource is not checked, so write the role in the resource.
- A policy resource is read through the `google_iam_policy` data source its `policy_data` names. That data source must sit in the same file and write its `binding` blocks out. A policy written any other way, or built with a `dynamic "binding"` block, is reported, because its members cannot be read. A project, folder or organization policy that cannot be read is the exception: nothing shows that it grants the Fine-Grained Reader role, so it is not reported.
- Only grants declared in the scanned files are read. A grant made outside Terraform, or on a folder or organization that is not in the scan, is not checked. On a project, folder or organization only the predefined role is matched: another role that carries the same permission, such as a custom role, is not read.

## References

- [google_data_catalog_policy_tag_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/data_catalog_policy_tag_iam)
- [google_project_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/google_project_iam)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

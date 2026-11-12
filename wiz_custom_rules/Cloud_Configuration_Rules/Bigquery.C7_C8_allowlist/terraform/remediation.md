Grant access to a dataset, table or view only to entities in `authorized_entities`, or, once an entity is approved, add it there in the rule's configuration. The rule reads every way Terraform grants that access: `access` blocks, `google_bigquery_dataset_access`, and the IAM member, binding and policy resources for datasets (`google_bigquery_dataset_iam_*`) and for tables and views (`google_bigquery_table_iam_*`):

```hcl
resource "google_bigquery_dataset" "example" {
  access {
    group_by_email = "data-team@yourcompany.com"
  }
}

resource "google_bigquery_dataset_access" "example" {
  user_by_email = "admin@yourcompany.com"
}

resource "google_bigquery_table_iam_member" "example" {
  dataset_id = "example_dataset"
  table_id   = "orders"
  role       = "roles/bigquery.dataViewer"
  member     = "group:data-team@yourcompany.com"
}
```

The matcher compares `user_by_email`, `group_by_email`, `domain`, `special_group`, `iam_member` and the `view`, `routine` and `dataset` entries against `authorized_entities`, written as `prefix:value`, such as `group:data-team@yourcompany.com`. An authorized view, routine or dataset is matched on its project, dataset and ID together, written `view:<project-id>.<dataset>.<table>`, `routine:<project-id>.<dataset>.<routine>` or `dataset:<project-id>.<dataset>`, so the same ID in another project or dataset is reported. An IAM `member` is compared as written, and every entry must match exactly. A service account listed as `user:<email>`, the form the dataset access list uses, is also approved as the IAM member `serviceAccount:<email>`.

Three limits of a source scan:

- A member set from a variable or another resource is not known until apply, so it is reported. Write the member in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- An IAM policy resource is read through the `google_iam_policy` data source its `policy_data` names. That data source must sit in the same file and write its `binding` blocks out. A policy written any other way, or built with a `dynamic "binding"` block, is reported, because its members cannot be read.
- A dataset that builds its `access` entries with a `dynamic "access"` block is reported, because the entries cannot be read. Write each `access` block out.

Roles granted on the project, folder or organization are inherited by every dataset and table. The rule does not read them, so a principal can reach a dataset through such a role without a finding here. The `projectOwners`, `projectWriters` and `projectReaders` entries give access to whoever holds those project roles, which the rule does not check either.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_dataset_access (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset_access)
- [google_bigquery_table_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table_iam)

Checked 2026-10-12 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

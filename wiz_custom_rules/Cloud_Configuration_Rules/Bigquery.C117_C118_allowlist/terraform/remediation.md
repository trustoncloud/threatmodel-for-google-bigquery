Grant access only to members approved in `authorized_access`, never to `allUsers` or `allAuthenticatedUsers`, and give `required_group` the owner role on every dataset. The rule reads every way Terraform grants dataset access: inline `access` blocks, `google_bigquery_dataset_access`, and `google_bigquery_dataset_iam_member`, `google_bigquery_dataset_iam_binding` and `google_bigquery_dataset_iam_policy`.

```hcl
resource "google_bigquery_dataset" "example" {
  dataset_id = "example_dataset"

  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }

  access {
    role           = "READER"
    group_by_email = "analysts@yourcompany.com"
  }
}

resource "google_bigquery_dataset" "by_iam" {
  dataset_id = "iam_managed_dataset"
}

resource "google_bigquery_dataset_iam_member" "admin" {
  dataset_id = google_bigquery_dataset.by_iam.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "group:data-admins@yourcompany.com"
}

resource "google_bigquery_dataset_iam_member" "reporting" {
  dataset_id = google_bigquery_dataset.by_iam.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:reporting@my-project.iam.gserviceaccount.com"
}
```

If a member is approved, add it to `authorized_access` in the rule's configuration instead: a user, group or domain-wide grant by its domain (`domains`) or exact address (`emails`), and a service account by its exact address (`service_accounts`) or the project that owns it (`project_ids`). A domain never approves a service account, and `yourcompany.com` does not approve its subdomains (add `*.yourcompany.com` for those).

Manage one dataset's access one way: the provider's dataset IAM resources and its `access` blocks or `google_bigquery_dataset_access` resources overwrite each other when they are mixed on the same dataset. In the IAM resources the owner role is written `roles/bigquery.dataOwner`; in `access` blocks it is `OWNER`. The rule accepts either name for `required_group`.

Limits of a source scan:

- A member set from a variable or another resource is not known until apply, so it is reported. Write the address in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- A grant in a separate resource counts for a dataset only when its `dataset_id` is that dataset's ID or a reference to it (`google_bigquery_dataset.<name>.dataset_id`), and both set the same `project`, or both leave it out and use the same provider configuration (the same `provider` alias; leaving `provider` out is the same as `provider = google`). A scan can hold files from several modules, each with its own default project, so this applies only when the two sit in the same file or the reference names a dataset resource that only one dataset in the scan has. In any other case both must set `project` to the same literal value.
- A `google_bigquery_dataset_iam_policy` is read through the `google_iam_policy` data source its `policy_data` names. That data source must sit in the same file and write its `binding` blocks out. A policy written any other way, or built with a `dynamic "binding"` block, is reported, because its members cannot be read.
- A dataset that builds its `access` entries with a `dynamic "access"` block is reported, because the members it grants cannot be read. Write each `access` block out.
- A grant with a `condition` does not count as the owner grant for `required_group`: it holds only while the condition does. A grant with a `dynamic` block counts as conditional, because the block can build a condition the source does not show. Give the group the owner role with no condition.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_dataset_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset_iam)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

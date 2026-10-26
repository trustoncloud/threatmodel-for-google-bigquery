Grant access only to identities in `authorized_domains`, never to `allUsers` or `allAuthenticatedUsers`, and give `required_group` the role in `required_role`, inline or in a `google_bigquery_dataset_access` resource whose `dataset_id` names the dataset. If a domain is approved, add it to `authorized_domains` in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  access {
    role           = "OWNER"
    group_by_email = "data-admins@yourcompany.com"
  }
}

resource "google_bigquery_dataset_access" "example" {
  dataset_id     = "example_dataset"
  role           = "READER"
  group_by_email = "analysts@yourcompany.com"
}
```

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_dataset_access (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset_access)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Grant dataset access, in `access` blocks or in `google_bigquery_dataset_access` resources, only to entities in `authorized_entities`, or, once an entity is approved, add it there in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  access {
    group_by_email = "data-team@yourcompany.com"
  }
}

resource "google_bigquery_dataset_access" "example" {
  user_by_email = "admin@yourcompany.com"
}
```

The matcher compares `user_by_email`, `group_by_email`, `domain`, `special_group`, `iam_member` and the `view`, `routine` and `dataset` entries against `authorized_entities`, written as `prefix:value`, such as `group:data-team@yourcompany.com`.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_dataset_access (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset_access)

Checked 2026-10-12 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

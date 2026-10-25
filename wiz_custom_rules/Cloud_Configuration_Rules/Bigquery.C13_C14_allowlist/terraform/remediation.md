List only principals from the domains in `authorized_domains` in `grantees`, or, once a domain is approved, add it to that list in the rule's configuration:

```hcl
resource "google_bigquery_row_access_policy" "example" {
  grantees = ["group:emea-sales@yourcompany.com"]
}
```

A grantee is matched on the domain after its `@`, so `domain:` grantees, `allUsers` and `allAuthenticatedUsers` are always reported.

## References

- [google_bigquery_row_access_policy (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_row_access_policy)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

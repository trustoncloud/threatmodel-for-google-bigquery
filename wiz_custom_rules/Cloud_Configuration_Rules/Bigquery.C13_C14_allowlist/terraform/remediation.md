List only grantees approved in `authorized_grantees` in `grantees`, or, once a grantee is approved, add it to that configuration: a user, group or domain-wide grant by its domain (`domains`) or exact address (`emails`), and a service account by its exact address (`service_accounts`) or the project that owns it (`project_ids`):

```hcl
resource "google_bigquery_row_access_policy" "example" {
  grantees = [
    "group:emea-sales@yourcompany.com",
    "serviceAccount:reporting@my-project.iam.gserviceaccount.com",
  ]
}
```

A domain never approves a service account, and `yourcompany.com` does not approve its subdomains (add `*.yourcompany.com` for those). `allUsers` and `allAuthenticatedUsers` are always reported. A grantee set from a variable or another resource is not known until apply, so it is reported: write the grantee in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

## References

- [google_bigquery_row_access_policy (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_row_access_policy)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

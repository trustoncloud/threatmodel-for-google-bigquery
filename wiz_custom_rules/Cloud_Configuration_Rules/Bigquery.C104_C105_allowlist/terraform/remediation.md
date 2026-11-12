Grant `roles/analyticshub.subscriber` and `roles/analyticshub.admin` on data exchanges and listings only to members approved in `authorized_subscribers` in the rule's configuration, or add the member there once approved: a user or group by its domain (`domains`) or exact address (`emails`), and a service account by its exact address (`service_accounts`) or the project that owns it (`project_ids`):

```hcl
resource "google_bigquery_analytics_hub_listing_iam_member" "example" {
  role   = "roles/analyticshub.subscriber"
  member = "group:subscribers@yourcompany.com"
}
```

The same applies to `members` in the `_iam_binding` resources and to the bindings of the `google_iam_policy` data source that an `_iam_policy` resource names in `policy_data`.

- A domain is matched exactly: `yourcompany.com` does not approve a longer name that ends with it, or its subdomains (add `*.yourcompany.com` for those). A domain never approves a service account.
- A grant to `allUsers`, `allAuthenticatedUsers` or a whole domain (`domain:`) is always reported.
- A member or role set from a variable or another resource is not known until apply, so the grant is reported. Write both in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.
- An `_iam_policy` resource is read only when `policy_data` names a `google_iam_policy` data source in the same file with its `binding` blocks written out. A policy built with a `dynamic` block, or taken from another file or a JSON string, is reported because its members cannot be read.
- This check reads the IAM grants that allow subscribing. A subscription that already exists stays in place after its grant is removed; the check of deployed subscriptions reports it until it is revoked.

## References

- [google_bigquery_analytics_hub_listing_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing_iam)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

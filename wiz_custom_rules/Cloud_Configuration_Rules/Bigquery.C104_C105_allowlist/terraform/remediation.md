Grant `roles/analyticshub.subscriber` and `roles/analyticshub.admin` on data exchanges and listings only to identities in a domain listed in `authorized_subscriber_domains` in the rule's configuration, or add the domain there once approved:

```hcl
resource "google_bigquery_analytics_hub_listing_iam_member" "example" {
  role   = "roles/analyticshub.subscriber"
  member = "group:subscribers@example.com"
}
```

The same applies to `members` in the `_iam_binding` resources and to the bindings in `policy_data` of the `_iam_policy` resources. A grant to `allUsers`, `allAuthenticatedUsers` or a `domain:` principal is always reported.

## References

- [google_bigquery_analytics_hub_listing_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing_iam)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

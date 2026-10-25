Grant roles on data policies only to principals listed in `authorized_principals`, or, once a principal is approved, add it to that list in the rule's configuration:

```hcl
resource "google_bigquery_datapolicy_data_policy_iam_member" "example" {
  member = "group:data-scientists@example.com"
}
```

The same applies to each entry in `members` of `google_bigquery_datapolicy_data_policy_iam_binding` and to every member in the `policy_data` of `google_bigquery_datapolicy_data_policy_iam_policy`. Principals are compared exactly as written, prefix included.

## References

- [google_bigquery_datapolicy_data_policy_iam_member (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_datapolicy_data_policy_iam)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

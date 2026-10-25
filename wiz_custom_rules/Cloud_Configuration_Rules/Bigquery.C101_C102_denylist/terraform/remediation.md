Keep secrets and personal data out of the listing's `display_name`, `description` and `documentation`, which the matcher tests against `sensitive_patterns` in the rule's configuration; narrow a pattern there only once the content it matches is approved:

```hcl
resource "google_bigquery_analytics_hub_listing" "example" {
  display_name  = "Regional sales"
  description   = "Daily sales totals by region."
  documentation = "Columns, refresh schedule and support channel for this listing."
}
```

A contact address belongs in `primary_contact`, which this matcher does not test.

## References

- [google_bigquery_analytics_hub_listing (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

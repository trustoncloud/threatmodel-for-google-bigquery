Set `primary_contact` on every data exchange and listing to an email address in a domain listed in `authorized_contact_domains` in the rule's configuration, or add the contact's domain there, with its leading `@`, once approved:

```hcl
resource "google_bigquery_analytics_hub_data_exchange" "example" {
  primary_contact = "data-owner@example.com"
}

resource "google_bigquery_analytics_hub_listing" "example" {
  primary_contact = "data-owner@example.com"
}
```

## References

- [google_bigquery_analytics_hub_data_exchange (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_data_exchange)
- [google_bigquery_analytics_hub_listing (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_analytics_hub_listing)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

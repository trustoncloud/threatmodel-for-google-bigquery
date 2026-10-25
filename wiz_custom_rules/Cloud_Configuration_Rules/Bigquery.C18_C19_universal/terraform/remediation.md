Set a default table expiration in milliseconds (at least 3600000), and keep the time travel window at or below `max_time_travel_hours` in the rule's configuration:

```hcl
resource "google_bigquery_dataset" "example" {
  default_table_expiration_ms = 2592000000
  max_time_travel_hours       = 168
}
```

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

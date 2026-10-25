Set the time travel window to at least `min_required_hours` from the rule's configuration, in multiples of 24 up to 168. A dataset that leaves `max_time_travel_hours` out gets 168:

```hcl
resource "google_bigquery_dataset" "example" {
  max_time_travel_hours = 168
}
```

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

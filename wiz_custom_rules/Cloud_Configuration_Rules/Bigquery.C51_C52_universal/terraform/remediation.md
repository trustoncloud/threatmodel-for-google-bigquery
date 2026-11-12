Set the time travel window to at least `min_required_hours` from the rule's configuration, in multiples of 24 up to 168. A dataset that leaves `max_time_travel_hours` out gets 168:

```hcl
resource "google_bigquery_dataset" "example" {
  max_time_travel_hours = 168
}
```

Two things to know about the rule's scope:

- A dataset with an `external_dataset_reference` block is skipped, because an external dataset has no time travel window.
- `min_required_hours` is 48 by default, which is also the shortest window BigQuery accepts. At that value the rule reports nothing. Raise it in the rule's configuration to enforce a longer window.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Declare reservations with an authorized `edition`, `ignore_idle_slots = true` and a `slot_capacity` within `max_slot_capacity`, and assignments with an authorized `job_type` and `assignee`. Once a value is approved, add it to the matching list in the rule's configuration:

```hcl
resource "google_bigquery_reservation" "example" {
  edition           = "ENTERPRISE"
  ignore_idle_slots = true
  slot_capacity     = 500
}

resource "google_bigquery_reservation_assignment" "example" {
  assignee = "projects/my-data-project"
  job_type = "QUERY"
}
```

A reservation that leaves out `edition` or `ignore_idle_slots` is reported.

## References

- [google_bigquery_reservation (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_reservation)
- [google_bigquery_reservation_assignment (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_reservation_assignment)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

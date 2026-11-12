Declare reservations with an authorized `edition`, `ignore_idle_slots = true` and a capacity within `max_slot_capacity`, and assignments with an authorized `job_type`, `assignee` and `reservation`. Once a value is approved, add it to the matching list in the rule's configuration:

```hcl
resource "google_bigquery_reservation" "example" {
  edition           = "ENTERPRISE"
  ignore_idle_slots = true
  slot_capacity     = 500

  autoscale {
    max_slots = 1000
  }
}

resource "google_bigquery_reservation_assignment" "example" {
  assignee    = "projects/my-data-project"
  job_type    = "QUERY"
  reservation = google_bigquery_reservation.example.id
}
```

A reservation that leaves out `edition` or `ignore_idle_slots` is reported.

- **Capacity.** `max_slot_capacity` covers what the reservation can reach: `slot_capacity` plus `autoscale.max_slots`. A reservation whose baseline is within the ceiling is reported when autoscaling can take it above.
- **Reservation target.** An assignment passes when its `reservation` points at a reservation declared in the same scan, which this rule then checks, or names one listed in `authorized_reservation_names_by_project_id` as `projects/<project-id>/locations/<location>/reservations/<name>`. The same name in another project or location is another reservation. A reference is resolved to the reservation in the same file, or, when that file declares none, to the only reservation with that resource name in the scan. `google_bigquery_reservation.<name>.id` is the full name of that reservation. `google_bigquery_reservation.<name>.name` is its short name only, so the assignment's own `project` and `location` decide which reservation it is: it is that reservation when the location is the same and the project is too (both state the same one, or both leave it to the same provider configuration), and otherwise it is matched like a bare name. A bare reservation name is matched only when the assignment also sets `project` and `location` as literal values.
- **Values not in the source.** A capacity set from a variable or another resource, or a reservation set from a variable, is not known until apply, so it is reported, and so is an `autoscale` block built with a `dynamic` block. Write the value in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

## References

- [google_bigquery_reservation (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_reservation)
- [google_bigquery_reservation_assignment (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_reservation_assignment)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

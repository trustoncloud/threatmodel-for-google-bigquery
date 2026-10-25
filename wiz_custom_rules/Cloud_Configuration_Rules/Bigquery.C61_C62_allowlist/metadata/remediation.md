# Remediation

The reservation or reservation assignment in the finding uses a configuration that is not authorized: an unauthorized edition, idle slot sharing left on, more baseline slots than the ceiling, or an assignment with an unauthorized job type or assignee. Correct it, or, once the configuration is approved, update `authorized_editions`, `required_ignore_idle_slots`, `max_slot_capacity`, `authorized_job_types` or `authorized_assignees` in the rule's configuration.

1. Keep the reservation to its own slots and its baseline within the ceiling:

   ```bash
   bq update --project_id=<admin-project-id> --location=<location> \
     --ignore_idle_slots=true --slots=<baseline-slots> --reservation <reservation>
   ```

2. An edition cannot be changed in place. Create a reservation in an authorized edition, move each assignment to it, then delete the old reservation:

   ```bash
   bq mk --project_id=<admin-project-id> --location=<location> --reservation \
     --edition=ENTERPRISE --slots=<baseline-slots> --ignore_idle_slots=true <new-reservation>
   bq update --project_id=<admin-project-id> --location=<location> --reservation_assignment \
     --destination_reservation_id=<new-reservation> <admin-project-id>:<location>.<reservation>.<assignment-id>
   bq rm --project_id=<admin-project-id> --location=<location> --reservation <reservation>
   ```

3. An assignment's job type and assignee are set when it is created. Delete an unauthorized assignment and, if needed, assign an authorized project, folder or organization:

   ```bash
   bq rm --project_id=<admin-project-id> --location=<location> \
     --reservation_assignment <reservation>.<assignment-id>
   bq mk --project_id=<admin-project-id> --location=<location> --reservation_assignment \
     --reservation_id=<reservation> --assignee_type=PROJECT --assignee_id=<project-id> --job_type=QUERY
   ```

Replace `<admin-project-id>`, `<location>` and `<reservation>` with the administration project, location and reservation in the finding, and `<assignment-id>` with the assignment's ID, which `bq ls --reservation_assignment --project_id=<admin-project-id> --location=<location>` lists. The rule has no cloud scan and judges only reservations and assignments declared in Terraform.

## References

- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [bq mk](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_mk)
- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [bq ls](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_ls)
- [Manage workload reservations](https://docs.cloud.google.com/bigquery/docs/reservations-tasks)
- [Manage workload assignments](https://docs.cloud.google.com/bigquery/docs/reservations-assignments)
- [Understand BigQuery editions](https://docs.cloud.google.com/bigquery/docs/editions-intro)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Use an unauthorized configuration with 1) a reservation, or 2) an assignment; it should be detected.

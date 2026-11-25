Point every trigger that scans BigQuery at a template listed in `authorized_templates`, with no inline `inspect_config` and a `status` of `HEALTHY` or unset, or, once the template is approved, add its full name to that list in the rule's configuration:

```hcl
resource "google_data_loss_prevention_job_trigger" "example" {
  status = "HEALTHY"

  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/strict-pii-v1"

    storage_config {
      big_query_options {
        # table_reference and sampling settings
      }
    }
  }
}
```

DLP merges an inline `inspect_config` into the template, so any inline `inspect_config` is reported, including one built by a `dynamic` block unless its `for_each` is a literal empty collection such as `[]` or `toset([])`. A template in the global location may be written with or without `locations/global`. A template name taken from a variable or another resource is not known until apply and is reported. A `PAUSED` or `CANCELLED` trigger runs no scans and is reported.

What the rule cannot show:

- An inspection job reports the sensitive data it finds and changes nothing in the table. A trigger with the right inspection rules does not show that sensitive data was found, or that it was redacted.
- Only the triggers declared in the scanned files are read. A sensitive table that no trigger scans gets no finding.

## References

- [google_data_loss_prevention_job_trigger (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/data_loss_prevention_job_trigger)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Point every trigger that scans BigQuery at a template listed in `authorized_templates`, or, once the template is approved, add its full name to that list in the rule's configuration:

```hcl
resource "google_data_loss_prevention_job_trigger" "example" {
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

The template name is compared exactly as written, so use the same form as the list. An inline `inspect_config` without an authorized template is reported.

## References

- [google_data_loss_prevention_job_trigger (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/data_loss_prevention_job_trigger)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

Give every trigger that scans BigQuery its inspection rules through `inspect_template_name`:

```hcl
resource "google_data_loss_prevention_job_trigger" "example" {
  inspect_job {
    inspect_template_name = "projects/my-project/inspectTemplates/my-template"

    storage_config {
      big_query_options {
        # table_reference and sampling settings
      }
    }
  }
}
```

An inline `inspect_config` block that lists the `info_types` to detect also satisfies the rule.

## References

- [google_data_loss_prevention_job_trigger (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/data_loss_prevention_job_trigger)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

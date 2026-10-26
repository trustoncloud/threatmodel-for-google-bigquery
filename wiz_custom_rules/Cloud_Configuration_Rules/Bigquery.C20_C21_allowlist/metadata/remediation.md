# Remediation

The Sensitive Data Protection job trigger in the finding scans BigQuery without one of the authorized inspection templates. Point the trigger at an authorized template, or, once its template is approved, add the template's full name to `authorized_templates` in the rule's configuration.

No GA `gcloud` or `bq` command edits a job trigger, so use the API method `projects.locations.jobTriggers.patch`:

1. Read the trigger:

   ```bash
   curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     "https://dlp.googleapis.com/v2/projects/<project-id>/locations/<location>/jobTriggers/<trigger-id>"
   ```

2. Copy its `inspectJob` object into `request.json`, set `inspectTemplateName` to an authorized template, written as in `authorized_templates`, and wrap it as `{"jobTrigger": {"inspectJob": ...}, "updateMask": "inspectJob"}`.

3. Apply the change:

   ```bash
   curl -s -X PATCH -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" -d @request.json \
     "https://dlp.googleapis.com/v2/projects/<project-id>/locations/<location>/jobTriggers/<trigger-id>"
   ```

Replace `<project-id>`, `<location>` and `<trigger-id>` with the trigger in the finding; a trigger created without a location is in `global`. The rule has no cloud scan and judges only triggers declared in Terraform, so review triggers created outside Terraform the same way.

## References

- [Using Sensitive Data Protection to scan BigQuery data](https://docs.cloud.google.com/bigquery/docs/scan-with-dlp)
- [Creating Sensitive Data Protection inspection templates](https://docs.cloud.google.com/sensitive-data-protection/docs/creating-templates-inspect)
- [Method: projects.locations.jobTriggers.patch](https://docs.cloud.google.com/sensitive-data-protection/docs/reference/rest/v2/projects.locations.jobTriggers/patch)

Checked 2026-10-06: links.

## Testing Compliance
Add non-redacted sensitive data; it should be detected.

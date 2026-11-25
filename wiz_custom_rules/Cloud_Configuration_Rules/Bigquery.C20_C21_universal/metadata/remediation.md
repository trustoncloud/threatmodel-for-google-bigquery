# Remediation

The Sensitive Data Protection job trigger in the finding scans BigQuery with no inspection rules (it names no inspection template and carries no inspection configuration), or it is paused or cancelled and runs no scans. Give it an inspection template, or an inspection configuration that lists the infoTypes to detect, and make sure it is `HEALTHY`.

No GA `gcloud` or `bq` command edits a job trigger, so use the API method `projects.locations.jobTriggers.patch`:

1. Save the trigger's error history, once per trigger. DLP can pause a trigger after repeated errors, which it lists in `errors`, and any change to the trigger clears that list. If you repeat these steps, keep the first `trigger-before.json` and skip this command:

   ```bash
   curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "x-goog-user-project: <quota-project-id>" \
     "https://dlp.googleapis.com/v2/projects/<project-id>/locations/<location>/jobTriggers/<trigger-id>" > trigger-before.json
   ```

2. Read the current trigger, and decide from it rather than from the finding:

   ```bash
   curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "x-goog-user-project: <quota-project-id>" \
     "https://dlp.googleapis.com/v2/projects/<project-id>/locations/<location>/jobTriggers/<trigger-id>" > trigger-now.json
   ```

   If `inspectJob` has neither an `inspectTemplateName` nor an `inspectConfig`, add inspection rules: copy the `inspectJob` object from `trigger-now.json` into a new `rules.json`, set `inspectTemplateName` to an inspection template (or add an `inspectConfig` with its `infoTypes`), wrap it as `{"jobTrigger": {"inspectJob": ...}, "updateMask": "inspectJob"}`, and apply it. Skip this step when the trigger already has rules.

   ```bash
   curl -s -X PATCH -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "x-goog-user-project: <quota-project-id>" \
     -H "Content-Type: application/json" -d @rules.json \
     "https://dlp.googleapis.com/v2/projects/<project-id>/locations/<location>/jobTriggers/<trigger-id>"
   ```

3. Read the trigger again with the command in step 2, writing to `trigger-after.json`. Check that `inspectJob` sets `inspectTemplateName` or an `inspectConfig`.

4. If `status` is `PAUSED`, resume it only once step 3 holds and you have fixed the cause of any `errors` in `trigger-before.json` (for example, a permission the DLP service agent lacks on the table), so it neither scans without rules nor fails and pauses again. Write `{"jobTrigger": {"status": "HEALTHY"}, "updateMask": "status"}` to a new `resume.json` and apply it:

   ```bash
   curl -s -X PATCH -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "x-goog-user-project: <quota-project-id>" \
     -H "Content-Type: application/json" -d @resume.json \
     "https://dlp.googleapis.com/v2/projects/<project-id>/locations/<location>/jobTriggers/<trigger-id>"
   ```

Replace `<project-id>`, `<location>` and `<trigger-id>` with the trigger in the finding. DLP refuses a user's credentials that name no quota project, so each command names one in `x-goog-user-project`: replace `<quota-project-id>` with a project that has the DLP API enabled and where you hold `serviceusage.services.use` (the Service Usage Consumer role grants it), often the trigger's own project. A trigger created without a location is in `global`. A cancelled trigger cannot be resumed, so create a replacement trigger and delete the cancelled one.

What the rule cannot show:

- An inspection job reports the sensitive data it finds and changes nothing in the table. A trigger with the right inspection rules does not show that sensitive data was found, or that it was redacted. Check redaction (de-identification or masking) on the data itself.
- Only the triggers that exist are read. A sensitive table that no trigger scans gets no finding, so compare your sensitive tables with the tables your triggers cover.

## References

- [Using Sensitive Data Protection to scan BigQuery data](https://docs.cloud.google.com/bigquery/docs/scan-with-dlp)
- [Creating Sensitive Data Protection inspection templates](https://docs.cloud.google.com/sensitive-data-protection/docs/creating-templates-inspect)
- [Method: projects.locations.jobTriggers.patch](https://docs.cloud.google.com/sensitive-data-protection/docs/reference/rest/v2/projects.locations.jobTriggers/patch)

Checked 2026-10-06: all links above resolve.

## Testing Compliance
Add non-redacted sensitive data; it should be detected.

# Remediation

The Gemini for Google Cloud API (`cloudaicompanion.googleapis.com`), which Gemini in BigQuery uses, is either enabled in a project that is not authorized for Gemini, or disabled in a project that is.

- In a project that is not authorized, disable the API, or, once Gemini is approved there, add the project ID to `authorized_gemini_projects` in the rule's configuration:

  ```bash
  gcloud services disable cloudaicompanion.googleapis.com --project=<project-id>
  ```

  Disabling it turns off every Gemini for Google Cloud product in the project. If the command refuses because the API was used in the last 30 days, was enabled in the last 3 days, or other enabled services depend on it, add `--force`.

- In an authorized project, enable the API, or remove the project from `authorized_gemini_projects` if it no longer needs Gemini:

  ```bash
  gcloud services enable cloudaicompanion.googleapis.com --project=<project-id>
  ```

Replace `<project-id>` with the project in the finding.

## References

- [gcloud services disable](https://docs.cloud.google.com/sdk/gcloud/reference/services/disable)
- [gcloud services enable](https://docs.cloud.google.com/sdk/gcloud/reference/services/enable)
- [Set up Gemini in BigQuery](https://docs.cloud.google.com/bigquery/docs/gemini-set-up)
- [Turn off Gemini products in Google Cloud](https://docs.cloud.google.com/gemini/docs/turn-off-gemini)
- [Enable and disable services](https://docs.cloud.google.com/service-usage/docs/enable-disable)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command syntax, flags and links.

## Testing Compliance
1) Enable Gemini in an unauthorized BigQuery project, or 2) disable Gemini from an authorized BigQuery project; it should be detected.

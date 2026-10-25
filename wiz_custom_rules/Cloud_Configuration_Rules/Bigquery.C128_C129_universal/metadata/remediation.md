# Remediation

The Gemini for Google Cloud API (`cloudaicompanion.googleapis.com`), which Gemini in BigQuery uses, is enabled in the project in the finding, and Gemini is not allowed in any project. Disable the API:

```bash
gcloud services disable cloudaicompanion.googleapis.com --project=<project-id>
```

Disabling it turns off every Gemini for Google Cloud product in the project, BigQuery included. If the command refuses because the API was used in the last 30 days, was enabled in the last 3 days, or other enabled services depend on it, add `--force`. Replace `<project-id>` with the project in the finding.

## References

- [gcloud services disable](https://docs.cloud.google.com/sdk/gcloud/reference/services/disable)
- [Turn off Gemini products in Google Cloud](https://docs.cloud.google.com/gemini/docs/turn-off-gemini)
- [Set up Gemini in BigQuery](https://docs.cloud.google.com/bigquery/docs/gemini-set-up)
- [Enable and disable services](https://docs.cloud.google.com/service-usage/docs/enable-disable)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command syntax, flags and links.

## Testing Compliance
1) Enable Gemini in an unauthorized BigQuery project, or 2) disable Gemini from an authorized BigQuery project; it should be detected.

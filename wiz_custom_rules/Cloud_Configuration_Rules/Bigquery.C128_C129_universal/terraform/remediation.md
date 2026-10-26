Remove every `google_project_service` that enables the Gemini for Google Cloud API:

```hcl
resource "google_project_service" "gemini" {
  service = "cloudaicompanion.googleapis.com"
}
```

Removing the resource leaves the API enabled unless it sets `disable_on_destroy = true`, so set that and apply before you remove it, or disable the API with `gcloud services disable cloudaicompanion.googleapis.com --project=<project-id>`.

## References

- [google_project_service (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/google_project_service)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

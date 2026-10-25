Enable `cloudaicompanion.googleapis.com` only in a project listed in `authorized_gemini_projects`, named in `project`, or, once a project is approved, add it to that list in the rule's configuration:

```hcl
resource "google_project_service" "gemini" {
  project = "example-project"
  service = "cloudaicompanion.googleapis.com"
}
```

A declaration that leaves out `project` takes the provider's default project, which the plan does not show, so it is reported.

## References

- [google_project_service (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/google_project_service)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

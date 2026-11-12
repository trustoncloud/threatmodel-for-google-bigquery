Enable `cloudaicompanion.googleapis.com` only in a project listed in `authorized_gemini_projects`, named in `project`, or, once a project is approved, add it to that list in the rule's configuration:

```hcl
resource "google_project_service" "gemini" {
  project = "example-project"
  service = "cloudaicompanion.googleapis.com"
}
```

The project ID is compared exactly with the list, so a project whose ID only contains an approved ID is reported. A declaration that leaves out `project` takes the provider's default project, which the source does not show, so it is reported. A project set from a variable or another resource is not known until apply, so it is reported: write the project ID in the resource. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

A limit of a source scan: the rule reports an enablement in a project that is not approved. It cannot report an approved project whose enablement is missing or was removed, because a resource that is absent from the source leaves nothing to read. The rule's cloud check reports that case once the project exists.

## References

- [google_project_service (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/google_project_service)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

A connection that declares an `aws` or `azure` block is a BigQuery Omni connection. Declare one only in a project listed in `authorized_omni_projects` in the rule's configuration, and write that project in the resource. Remove any other Omni connection, or, once its project is approved for Omni, add the project ID to `authorized_omni_projects`:

```hcl
resource "google_bigquery_connection" "example" {
  project       = "omni-analytics-prod"
  connection_id = "aws_link"
  location      = "aws-us-east-1"

  aws {
    access_role {
      iam_role_id = "arn:aws:iam::<aws-account-id>:role/<role-name>"
    }
  }
}
```

The provider's default project and a project taken from a variable or another resource are not in the source, so an Omni connection without a literal `project` is reported. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

The rule also reports an organization policy that weakens the Omni ban (`bigquery.disableBQOmniAWS` or `bigquery.disableBQOmniAzure`) anywhere except on an approved project: a rule with `enforce` not `"TRUE"`, a rule that enforces only under a `condition`, a `condition` or `rules` block built with a `dynamic` block (the source does not show what it builds), `reset = true`, a live `spec` with no rule, and, with the legacy resources, `boolean_policy` with `enforced` not `true` or a `restore_policy` block. A reset or restore returns the constraint to its default, which drops a ban inherited from the organization. Keep the ban enforced:

```hcl
resource "google_org_policy_policy" "disable_bq_omni_aws" {
  name   = "organizations/<organization-id>/policies/bigquery.disableBQOmniAWS"
  parent = "organizations/<organization-id>"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
```

A policy counts as set on an approved project when its `name` and `parent` (or, with `google_project_organization_policy`, its `project`) name that project by the ID written in `authorized_omni_projects`. Organization and folder policies are never exempt, and neither is a policy that names the project by its number. `dry_run_spec` is not live and is not read. A ban that Terraform does not declare is not reported, since it may be set elsewhere.

A policy can also set its constraint from a variable or another resource: in `name` after `/policies/`, or in `constraint` on the legacy resources. That constraint is not known until apply and could be an Omni constraint, so the policy is reported when it would weaken a ban anywhere except on an approved project: `enforce` not `"TRUE"`, a `condition`, a reset or restore, or a live `spec` with no rule. It is not reported when it enforces its constraint with no condition, or when every rule carries list settings (`values`, `allow_all` or `deny_all`), which the Omni constraints do not take. Write the constraint in the resource to clear the finding. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

## References

- [google_bigquery_connection (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_connection)
- [google_org_policy_policy (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/org_policy_policy)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

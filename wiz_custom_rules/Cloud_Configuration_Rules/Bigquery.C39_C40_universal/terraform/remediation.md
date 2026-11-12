Declare no BigQuery Omni connections (a `google_bigquery_connection` with an `aws` or `azure` block), and keep both Omni constraints enforced wherever Terraform declares them:

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

Declare the same for `bigquery.disableBQOmniAzure`; with the legacy resources, set `boolean_policy { enforced = true }`.

The rule reports every declaration that weakens the ban at an organization, folder or project: a rule with `enforce` not `"TRUE"`, a rule that enforces only under a `condition`, a `condition` or `rules` block built with a `dynamic` block (the source does not show what it builds), `reset = true`, a live `spec` with no rule, and, with the legacy resources, `boolean_policy` with `enforced` not `true` or a `restore_policy` block. A reset or restore returns the constraint to its default, which drops a ban inherited from the organization. `dry_run_spec` is not live and is not read. A ban that Terraform does not declare is not reported, since it may be set elsewhere.

A policy can also set its constraint from a variable or another resource: in `name` after `/policies/`, or in `constraint` on the legacy resources. That constraint is not known until apply and could be an Omni constraint, so the policy is reported when it would weaken a ban: `enforce` not `"TRUE"`, a `condition`, a reset or restore, or a live `spec` with no rule. It is not reported when it enforces its constraint with no condition, or when every rule carries list settings (`values`, `allow_all` or `deny_all`), which the Omni constraints do not take. Write the constraint in the resource to clear the finding. The exception is a variable that declares a default: the scan reads the Terraform source, so it checks that default. Terraform can deploy a value passed in its place, and a passing scan does not cover that value.

## References

- [google_org_policy_policy (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/org_policy_policy)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

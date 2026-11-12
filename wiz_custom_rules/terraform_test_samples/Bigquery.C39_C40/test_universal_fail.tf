# Bigquery.C40 (bigquery_omni_governance) - universal - VIOLATING

# Omni connection declared under a universal ban: 1 finding
resource "google_bigquery_connection" "azure_link" {
  connection_id = "azure_link"
  location      = "azure-eastus2"

  azure {
    customer_tenant_id = "00000000-0000-0000-0000-000000000000"
  }
}

# Project-level weakening of the Omni ban: 1 finding
resource "google_project_organization_policy" "omni_escape" {
  project    = "example-project"
  constraint = "constraints/bigquery.disableBQOmniAzure"

  boolean_policy {
    enforced = false
  }
}

# Reset to the constraint default, which drops the inherited ban: 1 finding
resource "google_org_policy_policy" "omni_reset" {
  name   = "projects/example-project/policies/bigquery.disableBQOmniAWS"
  parent = "projects/example-project"

  spec {
    reset = true
  }
}

# Legacy form of the same reset: 1 finding
resource "google_folder_organization_policy" "omni_restore" {
  folder     = "folders/123456789012"
  constraint = "constraints/bigquery.disableBQOmniAWS"

  restore_policy {
    default = true
  }
}

# Rule that turns the ban off: 1 finding
resource "google_org_policy_policy" "omni_unenforced" {
  name   = "folders/123456789012/policies/bigquery.disableBQOmniAzure"
  parent = "folders/123456789012"

  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# Ban enforced only where a condition holds, and off everywhere else:
# 2 findings
resource "google_org_policy_policy" "omni_conditional" {
  name   = "organizations/123456789012/policies/bigquery.disableBQOmniAzure"
  parent = "organizations/123456789012"

  spec {
    rules {
      enforce = "FALSE"
    }

    rules {
      enforce = "TRUE"

      condition {
        expression = "resource.matchTag('123456789012/environment', 'prod')"
      }
    }
  }
}

# Live spec with no rule, so nothing enforces the ban: 1 finding
resource "google_org_policy_policy" "omni_empty_spec" {
  name   = "projects/example-project/policies/bigquery.disableBQOmniAzure"
  parent = "projects/example-project"

  spec {
    inherit_from_parent = false
  }
}

# A constraint set from a variable with no default is not known until apply.
# A policy that does not enforce it could be turning the Omni ban off: 1 finding
variable "constraint" {
  type = string
}

resource "google_org_policy_policy" "variable_constraint_unenforced" {
  name   = "folders/123456789012/policies/${var.constraint}"
  parent = "folders/123456789012"

  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# Legacy form of the same case: 1 finding
resource "google_folder_organization_policy" "variable_constraint_legacy" {
  folder     = "folders/123456789012"
  constraint = var.constraint

  boolean_policy {
    enforced = false
  }
}

# A condition built with a dynamic block may limit where the constraint is
# enforced. The constraint is set from a variable, so it could be an Omni
# constraint: 1 finding
variable "policy_conditions" {
  type = list(object({ expression = string }))
}

resource "google_org_policy_policy" "variable_constraint_dynamic_condition" {
  name   = "folders/123456789012/policies/${var.constraint}"
  parent = "folders/123456789012"

  spec {
    rules {
      enforce = "TRUE"

      dynamic "condition" {
        for_each = var.policy_conditions

        content {
          expression = condition.value.expression
        }
      }
    }
  }
}

# The same condition on a policy that names an Omni constraint: 1 finding
resource "google_org_policy_policy" "omni_dynamic_condition" {
  name   = "folders/123456789012/policies/bigquery.disableBQOmniAWS"
  parent = "folders/123456789012"

  spec {
    rules {
      enforce = "TRUE"

      dynamic "condition" {
        for_each = var.policy_conditions

        content {
          expression = condition.value.expression
        }
      }
    }
  }
}

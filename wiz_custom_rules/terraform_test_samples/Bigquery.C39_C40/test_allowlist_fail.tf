# Bigquery.C40 (bigquery_omni_governance) - allowlist - VIOLATING

# Omni connection with no project written in the resource, so it cannot be
# matched to an approved project: 1 finding
resource "google_bigquery_connection" "aws_link" {
  connection_id = "aws_link"
  location      = "aws-us-east-1"

  aws {
    access_role {
      iam_role_id = "arn:aws:iam::123456789012:role/bigquery-omni"
    }
  }
}

# Omni connection in a project that is not approved: 1 finding
resource "google_bigquery_connection" "azure_link_other_project" {
  project       = "omni-analytics-prod-2"
  connection_id = "azure_link"
  location      = "azure-eastus2"

  azure {
    customer_tenant_id = "00000000-0000-0000-0000-000000000000"
  }
}

# Folder policy turning the Omni ban off: 1 finding
resource "google_folder_organization_policy" "omni_escape_folder" {
  folder     = "folders/123456789012"
  constraint = "constraints/bigquery.disableBQOmniAWS"

  boolean_policy {
    enforced = false
  }
}

# Project that is not approved turning the ban off: 1 finding
resource "google_project_organization_policy" "omni_escape_project" {
  project    = "analytics-prod"
  constraint = "constraints/bigquery.disableBQOmniAzure"

  boolean_policy {
    enforced = false
  }
}

# Project that is not approved resetting the ban to the default: 1 finding
resource "google_org_policy_policy" "omni_reset_project" {
  name   = "projects/analytics-prod/policies/bigquery.disableBQOmniAWS"
  parent = "projects/analytics-prod"

  spec {
    reset = true
  }
}

# Organization policy restoring the default: 1 finding
resource "google_organization_policy" "omni_restore_org" {
  org_id     = "123456789012"
  constraint = "constraints/bigquery.disableBQOmniAzure"

  restore_policy {
    default = true
  }
}

# A constraint set from a variable with no default is not known until apply.
# A policy that resets it on a project that is not approved could be dropping
# the Omni ban: 1 finding
variable "constraint" {
  type = string
}

resource "google_org_policy_policy" "variable_constraint_reset" {
  name   = "projects/analytics-prod/policies/${var.constraint}"
  parent = "projects/analytics-prod"

  spec {
    reset = true
  }
}

# Legacy form of the same case: 1 finding
resource "google_project_organization_policy" "variable_constraint_restore" {
  project    = "analytics-prod"
  constraint = var.constraint

  restore_policy {
    default = true
  }
}

# A condition built with a dynamic block may limit where the constraint is
# enforced. The constraint is set from a variable, so it could be an Omni
# constraint: 1 finding
variable "policy_conditions" {
  type = list(object({ expression = string }))
}

resource "google_org_policy_policy" "variable_constraint_dynamic_condition" {
  name   = "projects/analytics-prod/policies/${var.constraint}"
  parent = "projects/analytics-prod"

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
  name   = "projects/analytics-prod/policies/bigquery.disableBQOmniAWS"
  parent = "projects/analytics-prod"

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

# Bigquery.C40 (bigquery_omni_governance) - allowlist - COMPLIANT

# Native GCP connection: not Omni
resource "google_bigquery_connection" "spanner_link" {
  connection_id = "spanner_link"
  location      = "us"

  cloud_spanner {
    database = "projects/example-project/instances/main/databases/orders"
  }
}

# Omni connection in the project approved for Omni
resource "google_bigquery_connection" "approved_aws_link" {
  project       = "omni-analytics-prod"
  connection_id = "aws_link"
  location      = "aws-us-east-1"

  aws {
    access_role {
      iam_role_id = "arn:aws:iam::123456789012:role/bigquery-omni"
    }
  }
}

# The approved project lifts the ban for itself
resource "google_project_organization_policy" "approved_project_legacy" {
  project    = "omni-analytics-prod"
  constraint = "constraints/bigquery.disableBQOmniAWS"

  boolean_policy {
    enforced = false
  }
}

resource "google_org_policy_policy" "approved_project_azure" {
  name   = "projects/omni-analytics-prod/policies/bigquery.disableBQOmniAzure"
  parent = "projects/omni-analytics-prod"

  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# Organization keeps the ban enforced
resource "google_organization_policy" "omni_ban" {
  org_id     = "123456789012"
  constraint = "constraints/bigquery.disableBQOmniAWS"

  boolean_policy {
    enforced = true
  }
}

# A constraint that is not known until apply, turned off on the approved
# project only
variable "constraint" {
  type = string
}

resource "google_org_policy_policy" "variable_constraint_approved_project" {
  name   = "projects/omni-analytics-prod/policies/${var.constraint}"
  parent = "projects/omni-analytics-prod"

  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# A constraint that is not known until apply, enforced with no condition
resource "google_org_policy_policy" "variable_constraint_enforced" {
  name   = "organizations/123456789012/policies/${var.constraint}"
  parent = "organizations/123456789012"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

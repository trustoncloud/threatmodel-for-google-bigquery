# Bigquery.C40 (bigquery_omni_governance) - universal - COMPLIANT

# Non-Omni connection
resource "google_bigquery_connection" "cloudsql_link" {
  connection_id = "cloudsql_link"
  location      = "us"

  cloud_sql {
    instance_id = "example-project:us-central1:orders-db"
    database    = "orders"
    type        = "POSTGRES"

    credential {
      username = "bq_reader"
      password = "placeholder"
    }
  }
}

# Org policy keeping the Omni ban enforced
resource "google_organization_policy" "omni_ban" {
  org_id     = "123456789012"
  constraint = "constraints/bigquery.disableBQOmniAWS"

  boolean_policy {
    enforced = true
  }
}

# Current-style policy keeping the ban enforced. The dry-run spec is not
# live, so it does not weaken the ban.
resource "google_org_policy_policy" "omni_ban_azure" {
  name   = "organizations/123456789012/policies/bigquery.disableBQOmniAzure"
  parent = "organizations/123456789012"

  spec {
    rules {
      enforce = "TRUE"
    }
  }

  dry_run_spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# Reset of a constraint that is not an Omni constraint
resource "google_org_policy_policy" "other_constraint_reset" {
  name   = "projects/example-project/policies/compute.disableSerialPortAccess"
  parent = "projects/example-project"

  spec {
    reset = true
  }
}

resource "google_project_organization_policy" "other_constraint_restore" {
  project    = "example-project"
  constraint = "constraints/compute.disableSerialPortAccess"

  restore_policy {
    default = true
  }
}

# A constraint that is not known until apply, enforced with no condition:
# whatever it names, the policy does not turn a ban off
variable "constraint" {
  type = string
}

resource "google_org_policy_policy" "variable_constraint_enforced" {
  name   = "folders/123456789012/policies/${var.constraint}"
  parent = "folders/123456789012"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_folder_organization_policy" "variable_constraint_legacy_enforced" {
  folder     = "folders/123456789012"
  constraint = var.constraint

  boolean_policy {
    enforced = true
  }
}

# A list constraint that is not known until apply: the Omni constraints are
# boolean, so a rule with list values is not one of them
variable "list_constraint" {
  type = string
}

resource "google_org_policy_policy" "variable_list_constraint" {
  name   = "folders/123456789012/policies/${var.list_constraint}"
  parent = "folders/123456789012"

  spec {
    rules {
      values {
        allowed_values = ["in:us-locations"]
      }
    }
  }
}

resource "google_folder_organization_policy" "variable_list_constraint_legacy" {
  folder     = "folders/123456789012"
  constraint = var.list_constraint

  list_policy {
    allow {
      values = ["in:us-locations"]
    }
  }
}

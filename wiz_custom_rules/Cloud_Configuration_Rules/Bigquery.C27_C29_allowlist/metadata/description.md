# Description

Verify each BigQuery resource is encrypted using an authorized CMEK and its version.

This rule covers two paired controls: the Terraform matcher implements Bigquery.C27 (Directive); the cloud matcher verifies Bigquery.C29 (Assurance).

This rule covers the control's datasets (bigquery#dataset). Wiz evaluates one resource type per rule, so Bigquery.C29 ships one rule each for datasets and transferconfigs.

# Description

Verify each BigQuery resource is encrypted using an authorized CMEK and its version.

This rule verifies Bigquery.C29 (Assurance) through its cloud matcher. The Terraform matcher that implements the paired control Bigquery.C27 (Directive) ships in the rule Bigquery.C27_C29 - bigquery_cmek_encryption (allowlist).

This rule covers the control's transferconfigs (bigquerydatatransfer#TransferConfig). Wiz evaluates one resource type per rule, so Bigquery.C29 ships one rule each for datasets and transferconfigs.

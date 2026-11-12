# Description

Verify only authorized entities you control are subscribed to authorized listings and data exchanges.

This rule covers two paired controls: the Terraform matcher implements Bigquery.C108 (Directive); the cloud matcher verifies Bigquery.C109 (Assurance).

This rule covers the control's datasets (bigquery#dataset). Wiz evaluates one resource type per rule, so Bigquery.C109 ships one rule each for datasets and subscriptions.

# Description

Verify only authorized entities you control are subscribed to authorized listings and data exchanges.

This rule verifies Bigquery.C109 (Assurance) through its cloud matcher. The Terraform matcher that implements the paired control Bigquery.C108 (Directive) ships in the rule Bigquery.C108_C109 - bigquery_subscription_ingress (allowlist).

This rule covers the control's subscriptions (analyticshub#subscription). Wiz evaluates one resource type per rule, so Bigquery.C109 ships one rule each for datasets and subscriptions.

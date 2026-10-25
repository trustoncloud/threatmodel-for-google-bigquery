# Description

Verify only authorized IAM entities are allowed to access sensitive columns of a table by using data policies.

This rule implements Bigquery.C45 (Directive) through its Terraform matcher; Bigquery.C46 is the paired Assurance control (no runtime scan surface).

Because it has no cloud matcher it carries no target native type, so it will not appear while a Native Type filter is applied and it reports no cloud findings. Filter on 'Created by equals User' or 'Target Platform equals Terraform' to see it.

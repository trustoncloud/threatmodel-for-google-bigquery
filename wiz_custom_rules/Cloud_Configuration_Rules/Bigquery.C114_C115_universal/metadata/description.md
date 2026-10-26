# Description

Verify the restricted export for listings is enabled according to the requirements.

This rule implements Bigquery.C114 (Directive) through its Terraform matcher; Bigquery.C115 is the paired Assurance control (no runtime scan surface).

Because it has no cloud matcher it carries no target native type, so it will not appear while a Native Type filter is applied and it reports no cloud findings. Filter on 'Created by equals User' or 'Target Platform equals Terraform' to see it.

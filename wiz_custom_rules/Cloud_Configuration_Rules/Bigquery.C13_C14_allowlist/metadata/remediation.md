# Remediation

The row access policy in the finding grants rows of its table to a principal outside the authorized domains, or to `allUsers` or `allAuthenticatedUsers`. Recreate the policy with authorized grantees only, or, once the domain is approved, add it to `authorized_domains` in the rule's configuration.

1. List the table's row access policies with their filters and grantees:

   ```bash
   bq ls --row_access_policies <project-id>:<dataset>.<table>
   ```

2. Replace the policy, keeping its filter and granting only authorized principals:

   ```sql
   CREATE OR REPLACE ROW ACCESS POLICY <policy>
   ON `<project-id>.<dataset>.<table>`
   GRANT TO ('group:<group>@<authorized-domain>')
   FILTER USING (<filter-expression>);
   ```

   Run it in the BigQuery console or with `bq query --nouse_legacy_sql`.

To remove the policy instead, run this the same way:

```sql
DROP ROW ACCESS POLICY <policy> ON `<project-id>.<dataset>.<table>`;
```

BigQuery does not drop a table's last policy this way. `DROP ALL ROW ACCESS POLICIES` does, and then anyone who can read the table sees every row.

Replace `<project-id>`, `<dataset>`, `<table>` and `<policy>` with the table and policy in the finding, `<filter-expression>` with the filter that step 1 lists for it, and the grantee with an authorized principal. The rule has no cloud scan and judges only policies declared in Terraform, so use step 1 to review policies created outside Terraform.

## References

- [bq ls](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_ls)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Use row-level security](https://docs.cloud.google.com/bigquery/docs/managing-row-level-security)
- [Introduction to BigQuery row-level security](https://docs.cloud.google.com/bigquery/docs/row-level-security-intro)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Configure an unauthorized IAM entity with access to a sensitive row; it should be detected.

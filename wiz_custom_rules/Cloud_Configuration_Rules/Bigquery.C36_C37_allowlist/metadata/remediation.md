# Remediation

A table in the finding declares a designated sensitive column with a type other than `BYTES`, so the column cannot hold AEAD ciphertext, or declares its schema in a way the scan cannot read, or a declared query job names a sensitive table and calls no AEAD encryption function. Encrypt the column with an AEAD function, store the result in a `BYTES` column, and encrypt the column in every query that writes it.

1. Table: encrypt the column in place. Add a `BYTES` column, fill it with ciphertext, drop the plaintext column, and give the new column the old name. `<wrapped-keyset>` is a keyset wrapped by your Cloud KMS key, created once with `KEYS.NEW_WRAPPED_KEYSET`. `AEAD.ENCRYPT` takes a `STRING` or `BYTES` value, so cast a column of another type with `CAST(<column> AS STRING)`:

   ```sql
   ALTER TABLE `<project-id>.<dataset>.<table>` ADD COLUMN <column>_enc BYTES;

   UPDATE `<project-id>.<dataset>.<table>`
   SET <column>_enc = AEAD.ENCRYPT(
     KEYS.KEYSET_CHAIN('gcp-kms://<kms-key-name>', <wrapped-keyset>),
     <column>, '<additional-data>')
   WHERE TRUE;

   ALTER TABLE `<project-id>.<dataset>.<table>` DROP COLUMN <column>;

   ALTER TABLE `<project-id>.<dataset>.<table>` RENAME COLUMN <column>_enc TO <column>;
   ```

   Run it in the BigQuery console or with `bq query --nouse_legacy_sql`. Until the dataset's time travel window passes, the dropped plaintext column can still be restored.

2. Query job: a job cannot be changed once it has run. Cancel it if it is still running, and write future queries on sensitive tables with `AEAD.ENCRYPT` or `DETERMINISTIC_ENCRYPT`:

   ```bash
   bq cancel <project-id>:<location>.<job-id>
   ```

If a column holds no sensitive data, remove it from `sensitive_columns`, or its table from `sensitive_table_refs`, in the rule's configuration instead. `sensitive_columns` lists each table as `dataset.table`, so a table with the same ID in another dataset is not affected. A query names a table in `sensitive_table_refs` when the dataset and table ID appear side by side in its text, with or without a project or backticks, in any case, so a table with a longer name is not affected either. Replace `<project-id>`, `<dataset>`, `<table>`, `<column>`, `<location>` and `<job-id>` with the resource the finding names, `<kms-key-name>` with your key's resource name (`projects/.../cryptoKeys/...`), and `<additional-data>` with the context you will also pass to decrypt.

What the rule cannot show:

- A `BYTES` column can hold any bytes. The type shows that the column can store ciphertext. It does not show that the values in it are encrypted, so confirm that on the data, for example by decrypting a sample with the keyset.
- The query text is not parsed. A query passes when `AEAD.ENCRYPT` or `DETERMINISTIC_ENCRYPT` appears anywhere in it, even in a comment or applied to another column, and a query that reaches a sensitive table through a view, a wildcard or a name built when the query runs is not seen.
- Only tables and jobs declared in Terraform are checked. Tables created and queries run outside Terraform are not.

## References

- [bq cancel](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cancel)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Column-level encryption with Cloud KMS](https://docs.cloud.google.com/bigquery/docs/column-key-encrypt)
- [AEAD encryption concepts](https://docs.cloud.google.com/bigquery/docs/aead-encryption-concepts)
- [Manage jobs](https://docs.cloud.google.com/bigquery/docs/managing-jobs)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Do not encrypt the data at the column level; it should be detected.

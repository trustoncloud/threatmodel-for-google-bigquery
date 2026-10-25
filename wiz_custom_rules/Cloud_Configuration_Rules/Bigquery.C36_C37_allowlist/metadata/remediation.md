# Remediation

A table in the finding stores a designated sensitive column in plaintext, or a declared query job reads a sensitive table without an AEAD encryption function. Store the column as AEAD ciphertext, and encrypt it in every query that writes it.

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

If a column holds no sensitive data, remove it from `sensitive_columns`, or its table from `sensitive_table_refs`, in the rule's configuration instead. Only tables and jobs declared in Terraform are checked. Replace `<project-id>`, `<dataset>`, `<table>`, `<column>`, `<location>` and `<job-id>` with the resource the finding names, `<kms-key-name>` with your key's resource name (`projects/.../cryptoKeys/...`), and `<additional-data>` with the context you will also pass to decrypt.

## References

- [bq cancel](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cancel)
- [bq query](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_query)
- [Column-level encryption with Cloud KMS](https://docs.cloud.google.com/bigquery/docs/column-key-encrypt)
- [AEAD encryption concepts](https://docs.cloud.google.com/bigquery/docs/aead-encryption-concepts)
- [Manage jobs](https://docs.cloud.google.com/bigquery/docs/managing-jobs)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Do not encrypt the data at the column level; it should be detected.

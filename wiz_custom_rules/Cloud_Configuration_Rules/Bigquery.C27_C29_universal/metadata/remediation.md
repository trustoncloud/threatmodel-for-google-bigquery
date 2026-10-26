# Remediation

The dataset in the finding has no default customer-managed encryption key (CMEK), so its tables use Google-managed encryption. Set a Cloud KMS key in the dataset's location as its default key, and re-encrypt the tables it already holds.

1. Grant the project's BigQuery service account the Encrypter/Decrypter role on the key. `bq show --encryption_service_account --project_id=<project-id>` prints the account:

   ```bash
   gcloud kms keys add-iam-policy-binding \
     projects/<kms-project-id>/locations/<location>/keyRings/<key-ring>/cryptoKeys/<key> \
     --member=serviceAccount:bq-<project-number>@bigquery-encryption.iam.gserviceaccount.com \
     --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
   ```

2. Set the key as the dataset's default key:

   ```bash
   bq update --dataset \
     --default_kms_key=projects/<kms-project-id>/locations/<location>/keyRings/<key-ring>/cryptoKeys/<key> \
     <project-id>:<dataset>
   ```

3. The default key applies only to tables created afterward. Copy each existing table onto itself under the key:

   ```bash
   bq cp --force \
     --destination_kms_key=projects/<kms-project-id>/locations/<location>/keyRings/<key-ring>/cryptoKeys/<key> \
     <project-id>:<dataset>.<table> <project-id>:<dataset>.<table>
   ```

Replace `<project-id>` and `<dataset>` with the dataset named in the finding, `<table>` with each of its tables, `<project-number>` with that project's number, and the key path with your key. For a table reported by the Terraform matcher, step 3 is enough.

## References

- [gcloud kms keys add-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/add-iam-policy-binding)
- [bq update](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_update)
- [bq cp](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_cp)
- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [Customer-managed Cloud KMS keys](https://docs.cloud.google.com/bigquery/docs/customer-managed-encryption)

Checked 2026-10-06 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Use an unauthorized 1) CMEK or a 2) version with a BigQuery resource; it should be detected.

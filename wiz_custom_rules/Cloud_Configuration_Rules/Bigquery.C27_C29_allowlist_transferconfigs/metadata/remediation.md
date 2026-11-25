# Remediation

The transfer configuration in the finding has no customer-managed encryption key (CMEK), or its key is not one the rule approves. The key covers the data the transfer stages and the tables it loads. Set an approved Cloud KMS key from `authorized_kms_keys`, in the transfer's location.

1. If the project's BigQuery service account cannot use the key yet, grant it the Encrypter/Decrypter role. `bq show --encryption_service_account --project_id=<project-id>` prints the account:

   ```bash
   gcloud kms keys add-iam-policy-binding \
     projects/<kms-project-id>/locations/<location>/keyRings/<key-ring>/cryptoKeys/<key> \
     --member=serviceAccount:bq-<project-number>@bigquery-encryption.iam.gserviceaccount.com \
     --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
   ```

2. A transfer created with a key can take another one: follow "Update a transfer" in Manage transfers, linked below. A key cannot be added to a transfer created without one, so replace that transfer with a copy that carries the key.

   Build the copy from the transfer's own configuration so it keeps the schedule, schedule options, parameters and notification settings. A transfer created from the command line without a schedule falls back to the data source's default schedule. Save the configuration:

   ```bash
   bq show --format=prettyjson --transfer_config \
     projects/<project-number>/locations/<location>/transferConfigs/<transfer-id> > transfer.json
   ```

   In `transfer.json`, delete `name`, set `disabled` to `true` so the copy does not run before you check it, and add the key:

   ```json
   "encryptionConfiguration": {
     "kmsKeyName": "projects/<kms-project-id>/locations/<location>/keyRings/<key-ring>/cryptoKeys/<key>"
   }
   ```

3. Create the copy. When `ownerInfo` in `transfer.json` names a service account, keep `serviceAccountName` so the copy runs as the same account; otherwise remove it and the copy runs as you. For a data source whose transfer page asks you to authorize it in the console, create the copy there instead, with the same settings and the key, and leave it disabled:

   ```bash
   curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d @transfer.json \
     "https://bigquerydatatransfer.googleapis.com/v1/projects/<project-id>/locations/<location>/transferConfigs?serviceAccountName=<service-account-email>"
   ```

4. Compare the copy with `transfer.json`. Then disable the original, and check that `bq show` now reports it with `"disabled": true`:

   ```bash
   bq show --format=prettyjson --transfer_config \
     projects/<project-number>/locations/<location>/transferConfigs/<new-transfer-id>

   curl -X PATCH \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{"disabled": true}' \
     "https://bigquerydatatransfer.googleapis.com/v1/projects/<project-id>/locations/<location>/transferConfigs/<transfer-id>?updateMask=disabled"

   bq show --format=prettyjson --transfer_config \
     projects/<project-number>/locations/<location>/transferConfigs/<transfer-id>
   ```

5. A run that started before the original was disabled keeps going. Repeat the listing below until it returns no runs, then enable the copy, so the two never load at the same time:

   ```bash
   bq ls --transfer_run --filter="states:PENDING,RUNNING" \
     projects/<project-number>/locations/<location>/transferConfigs/<transfer-id>

   curl -X PATCH \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{"disabled": false}' \
     "https://bigquerydatatransfer.googleapis.com/v1/projects/<project-id>/locations/<location>/transferConfigs/<new-transfer-id>?updateMask=disabled"
   ```

6. Delete the original only after the copy has completed a run you have checked:

   ```bash
   bq rm --transfer_config \
     projects/<project-number>/locations/<location>/transferConfigs/<transfer-id>
   ```

   To go back to the original before then, run steps 4 and 5 the other way round: disable the copy, confirm it reports `"disabled": true`, wait until the listing returns no pending or running runs of the copy, and only then enable the original.

If the key in the finding is approved, add its full name to `authorized_kms_keys` in the rule's configuration instead, here and in the copy of the configuration that the rule for datasets of this control carries. A key matches an entry only when project, location, key ring and key are all the same, so a key with a longer name or in another key ring is reported.

The rule reads the key the transfer has in effect, which can be the project default key applied when the transfer was created. A transfer from a data source outside `cmek_capable_transfer_sources` is skipped, because the transfer takes no key for it. Add a source to that list only when its BigQuery Data Transfer Service page documents a customer-managed key for it, and set it in both copies of the configuration.

Replace `<project-id>` and `<project-number>` with the project that holds the transfer named in the finding, `<location>` and `<transfer-id>` with the transfer's location and ID, `<new-transfer-id>` with the ID the create call returns, and the key path with the approved key.

## References

- [gcloud kms keys add-iam-policy-binding](https://docs.cloud.google.com/sdk/gcloud/reference/kms/keys/add-iam-policy-binding)
- [bq show](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_show)
- [bq ls](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_ls)
- [transferConfigs.create](https://docs.cloud.google.com/bigquery/docs/reference/datatransfer/rest/v1/projects.locations.transferConfigs/create)
- [transferConfigs.patch](https://docs.cloud.google.com/bigquery/docs/reference/datatransfer/rest/v1/projects.locations.transferConfigs/patch)
- [bq rm](https://docs.cloud.google.com/bigquery/docs/reference/bq-cli-reference#bq_rm)
- [Manage transfers](https://docs.cloud.google.com/bigquery/docs/working-with-transfers)
- [Scheduling queries](https://docs.cloud.google.com/bigquery/docs/scheduling-queries)

Checked 2026-11-18 with Google Cloud CLI 587.0.0: command flags and links.

## Testing Compliance
Use an unauthorized 1) CMEK or a 2) version with a BigQuery resource; it should be detected.

Give every dataset a default Cloud KMS key and every table its own key:

```hcl
resource "google_bigquery_dataset" "example" {
  default_encryption_configuration {
    kms_key_name = "projects/example-project/locations/us/keyRings/example-ring/cryptoKeys/example-key"
  }
}

resource "google_bigquery_table" "example" {
  encryption_configuration {
    kms_key_name = "projects/example-project/locations/us/keyRings/example-ring/cryptoKeys/example-key"
  }
}
```

The matcher judges each table by its own `encryption_configuration`, so set it even when the dataset has a default key. BigQuery's service account needs the Cloud KMS CryptoKey Encrypter/Decrypter role on the key.

## References

- [google_bigquery_dataset (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_dataset)
- [google_bigquery_table (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_table)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

A connection that declares an `aws` or `azure` block is a BigQuery Omni connection. Remove the connection, or, once that cloud is approved for Omni, add `"AWS"` or `"AZURE"` to `authorized_omni_clouds` in the rule's configuration:

```hcl
resource "google_bigquery_connection" "example" {
  aws {
    # reported unless "AWS" is in authorized_omni_clouds
  }
  azure {
    # reported unless "AZURE" is in authorized_omni_clouds
  }
}
```

## References

- [google_bigquery_connection (hashicorp/google 8.5.0)](https://registry.terraform.io/providers/hashicorp/google/8.5.0/docs/resources/bigquery_connection)

Checked 2026-10-06 against hashicorp/google 7.46.1 and 8.5.0: resources, arguments and links.

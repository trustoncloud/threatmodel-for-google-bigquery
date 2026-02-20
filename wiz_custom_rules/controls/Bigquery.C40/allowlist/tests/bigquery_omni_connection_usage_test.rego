package wiz

# 1. FAIL: AWS Connection (Since allowlist is empty)
test_allowlist_fail_aws {
    result == "fail" with input as {
        "type": "google_bigquery_connection",
        "name": "aws-link",
        "properties": {
            "aws": { "accessRole": "..." }
        }
    }
}

# 2. FAIL: Azure Connection
test_allowlist_fail_azure {
    result == "fail" with input as {
        "type": "google_bigquery_connection",
        "name": "azure-link",
        "properties": {
            "azure": { "application": "..." }
        }
    }
}

# 3. PASS: Native GCP Connection (Always allowed)
test_allowlist_pass_gcp {
    result == "pass" with input as {
        "type": "google_bigquery_connection",
        "name": "sql-link",
        "properties": {
            "cloudSql": { "instanceId": "..." }
        }
    }
}
package wiz

# 1. PASS: Authorized Template
test_allowlist_pass_authorized {
    result == "pass" with input as {
        "name": "compliant-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                "inspectTemplateName": "projects/my-project/inspectTemplates/strict-pii-v1",
                "storageConfig": {
                    "bigQueryOptions": { "tableReference": "..." }
                }
            }
        }
    }
}

# 2. FAIL: Unauthorized Template
test_allowlist_fail_unauthorized {
    result == "fail" with input as {
        "name": "rogue-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                "inspectTemplateName": "projects/my-project/inspectTemplates/shadow-it-template",
                "storageConfig": {
                    "bigQueryOptions": { "tableReference": "..." }
                }
            }
        }
    }
}

# 3. FAIL: Inline Configuration (Strict Mode Violation)
# Allowlist mode enforces usage of Managed Templates. Inline ad-hoc rules are rejected.
test_allowlist_fail_inline_config {
    result == "fail" with input as {
        "name": "ad-hoc-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                "inspectConfig": { "infoTypes": [{"name": "EMAIL_ADDRESS"}] },
                "storageConfig": {
                    "bigQueryOptions": { "tableReference": "..." }
                }
            }
        }
    }
}

# 4. SKIP: Not targeting BigQuery
test_allowlist_skip_gcs {
    result == "skip" with input as {
        "name": "gcs-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                "inspectTemplateName": "projects/my-project/inspectTemplates/strict-pii-v1",
                "storageConfig": {
                    "cloudStorageOptions": { "bucketName": "..." }
                }
            }
        }
    }
}
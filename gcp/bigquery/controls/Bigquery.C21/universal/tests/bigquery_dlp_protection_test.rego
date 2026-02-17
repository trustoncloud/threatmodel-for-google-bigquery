package wiz

# 1. PASS: Trigger using a Template (Best Practice)
test_universal_pass_template {
    result == "pass" with input as {
        "name": "template-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                "inspectTemplateName": "projects/my-project/inspectTemplates/any-template",
                "storageConfig": {
                    "bigQueryOptions": { "tableReference": "..." }
                }
            }
        }
    }
}

# 2. PASS: Trigger using Inline Config (Ad-hoc)
# Universal mode just checks "is it scanning?", so inline config is acceptable.
test_universal_pass_inline {
    result == "pass" with input as {
        "name": "inline-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                # No template name, but has inline config
                "inspectConfig": {
                    "infoTypes": [{"name": "CREDIT_CARD_NUMBER"}]
                },
                "storageConfig": {
                    "bigQueryOptions": { "tableReference": "..." }
                }
            }
        }
    }
}

# 3. FAIL: Trigger targeting BigQuery but missing BOTH Template and Config
test_universal_fail_empty_job {
    result == "fail" with input as {
        "name": "broken-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                # Missing inspectTemplateName AND inspectConfig
                "storageConfig": {
                    "bigQueryOptions": { "tableReference": "..." }
                }
            }
        }
    }
}

# 4. SKIP: Trigger targets Cloud Storage (Not relevant to BigQuery control)
test_universal_skip_gcs {
    result == "skip" with input as {
        "name": "gcs-scanner",
        "type": "google_dlp_job_trigger",
        "properties": {
            "inspectJob": {
                "inspectTemplateName": "projects/my-project/inspectTemplates/any-template",
                "storageConfig": {
                    "cloudStorageOptions": { "bucketName": "..." }
                }
            }
        }
    }
}
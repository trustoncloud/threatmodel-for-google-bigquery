package wiz

# 1. PASS: Policy Tag with only authorized members
test_pass_authorized {
    result == "pass" with input as {
        "name": "sensitive-tag",
        "type": "google_datacatalog_policy_tag",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/datacatalog.categoryFineGrainedReader",
                        "members": ["group:sensitive-data-readers@example.com"]
                    }
                ]
            }
        }
    }
}

# 2. FAIL: Policy Tag with an unauthorized user
test_fail_unauthorized_user {
    result == "fail" with input as {
        "name": "sensitive-tag",
        "type": "google_datacatalog_policy_tag",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/datacatalog.categoryFineGrainedReader",
                        "members": ["user:hacker@evil.com"]
                    }
                ]
            }
        }
    }
}

# 3. FAIL: Policy Tag with unauthorized Service Account (even with a different role)
test_fail_unauthorized_sa {
    result == "fail" with input as {
        "name": "sensitive-tag",
        "type": "google_datacatalog_policy_tag",
        "properties": {
            "iamPolicy": {
                "bindings": [
                    {
                        "role": "roles/owner",
                        "members": ["serviceAccount:random-sa@project.iam.gserviceaccount.com"]
                    }
                ]
            }
        }
    }
}

# 4. SKIP: Not a Policy Tag resource (e.g., a Table)
test_skip_wrong_resource {
    result == "skip" with input as {
        "name": "my-table",
        "type": "google_bigquery_table"
    }
}
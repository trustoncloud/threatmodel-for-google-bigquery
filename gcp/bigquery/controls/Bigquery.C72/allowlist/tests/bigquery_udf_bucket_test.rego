package wiz

# --- TEST 1: PASS - Authorized Bucket ---
test_pass_valid_bucket {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "safe-job",
        "properties": {
            "configuration": {
                "query": {
                    "userDefinedFunctionResources": [
                        { "resourceUri": "gs://my-corp-trusted-scripts/math_lib.js" }
                    ]
                }
            }
        }
    }
}

# --- TEST 2: PASS - Inline Code (Ignored by this control) ---
test_pass_inline_code {
    result == "pass" with input as {
        "type": "google_bigquery_job",
        "name": "inline-job",
        "properties": {
            "configuration": {
                "query": {
                    "userDefinedFunctionResources": [
                        { "inlineCode": "return x+1;" }
                    ]
                }
            }
        }
    }
}

# --- TEST 3: FAIL - Unauthorized Bucket ---
test_fail_untrusted_bucket {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "risky-job",
        "properties": {
            "configuration": {
                "query": {
                    "userDefinedFunctionResources": [
                        # This bucket is not in the allowlist
                        { "resourceUri": "gs://hacker-public-bucket/malware.js" }
                    ]
                }
            }
        }
    }
}

# --- TEST 4: FAIL - Mixed (One valid, one invalid) ---
test_fail_mixed {
    result == "fail" with input as {
        "type": "google_bigquery_job",
        "name": "mixed-job",
        "properties": {
            "configuration": {
                "query": {
                    "userDefinedFunctionResources": [
                        { "resourceUri": "gs://my-corp-trusted-scripts/math_lib.js" },
                        { "resourceUri": "gs://unknown-bucket/spyware.js" }
                    ]
                }
            }
        }
    }
}
package wiz

# 1. PASS: Policy Enforced (Omni Disabled)
test_universal_pass {
    result == "pass" with input as {
        "type": "google_organization_policy",
        "name": "disable-aws",
        "properties": {
            "constraint": "constraints/bigquery.disableBQOmniAWS",
            "booleanPolicy": { "enforced": true }
        }
    }
}

# 2. FAIL: Policy Not Enforced (Omni Allowed)
test_universal_fail {
    result == "fail" with input as {
        "type": "google_organization_policy",
        "name": "allow-azure",
        "properties": {
            "constraint": "constraints/bigquery.disableBQOmniAzure",
            "booleanPolicy": { "enforced": false }
        }
    }
}

# 3. SKIP: Irrelevant Policy
test_universal_skip {
    result == "skip" with input as {
        "type": "google_organization_policy",
        "properties": {
            "constraint": "constraints/compute.disableSerialPortAccess"
        }
    }
}
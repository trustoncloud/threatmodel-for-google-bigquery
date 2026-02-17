package wiz

# 1. PASS: Explicit 7 days (168 hours)
test_pass_standard {
    result == "pass" with input as {
        "properties": {"maxTimeTravelHours": "168"}
    }
}

# 2. FAIL: Disabled/Too short (24 hours)
test_fail_short {
    result == "fail" with input as {
        "properties": {"maxTimeTravelHours": "24"}
    }
}

# 3. PASS: Default (Property missing implies 168 hours in GCP)
test_pass_default {
    result == "pass" with input as {
        "properties": {}
    }
}
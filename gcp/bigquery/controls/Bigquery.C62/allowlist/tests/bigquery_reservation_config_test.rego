package wiz

# --- TEST CASE 1: RESERVATIONS ---

# PASS: Valid Reservation
test_pass_reservation {
    result == "pass" with input as {
        "type": "google_bigquery_reservation",
        "name": "prod-reservation",
        "properties": {
            "edition": "ENTERPRISE",
            "ignoreIdleSlots": true,
            "slotCapacity": "100"
        }
    }
}

# FAIL: Wrong Edition
test_fail_reservation_edition {
    result == "fail" with input as {
        "type": "google_bigquery_reservation",
        "name": "bad-edition",
        "properties": {
            "edition": "STANDARD", # Unauthorized
            "ignoreIdleSlots": true,
            "slotCapacity": "100"
        }
    }
}

# FAIL: Exceeds Max Slots
test_fail_reservation_capacity {
    result == "fail" with input as {
        "type": "google_bigquery_reservation",
        "name": "too-big",
        "properties": {
            "edition": "ENTERPRISE",
            "ignoreIdleSlots": true,
            "slotCapacity": "5000" # Exceeds limit of 2000
        }
    }
}

# --- TEST CASE 2: ASSIGNMENTS ---

# PASS: Valid Assignment
test_pass_assignment {
    result == "pass" with input as {
        "type": "google_bigquery_reservation_assignment",
        "name": "prod-assignment",
        "properties": {
            "jobType": "QUERY",
            "assignee": "projects/my-data-project"
        }
    }
}

# FAIL: Wrong Job Type
test_fail_assignment_job {
    result == "fail" with input as {
        "type": "google_bigquery_reservation_assignment",
        "name": "bad-job",
        "properties": {
            "jobType": "BACKGROUND", # Unauthorized
            "assignee": "projects/my-data-project"
        }
    }
}

# FAIL: Unauthorized Assignee
test_fail_assignment_assignee {
    result == "fail" with input as {
        "type": "google_bigquery_reservation_assignment",
        "name": "rogue-team",
        "properties": {
            "jobType": "QUERY",
            "assignee": "projects/unknown-shadow-it"
        }
    }
}

# --- TEST CASE 3: OTHER ---
test_skip_other {
    result == "skip" with input as {
        "type": "google_bigquery_dataset"
    }
}
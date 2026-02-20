package wiz

# --- TEST 1: PASS - Partitioned & Safe ---
test_pass_safe_partitioned {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/logs_2024",
        "properties": {
            "timePartitioning": { "type": "DAY" },
            "requirePartitionFilter": true # PASS
        }
    }
}

# --- TEST 2: FAIL - Partitioned & Unsafe (The Risk) ---
test_fail_unsafe_partitioned {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/huge_logs",
        "properties": {
            "timePartitioning": { "type": "DAY" },
            "requirePartitionFilter": false # FAIL: Risk of full scan
        }
    }
}

# --- TEST 3: PASS - Not Partitioned (Not Applicable) ---
# A standard table doesn't need this filter because it doesn't have partitions to filter by.
test_pass_standard_table {
    result == "pass" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/small_lookup",
        "properties": {
            # No partitioning keys
            "requirePartitionFilter": false 
        }
    }
}

# --- TEST 4: FAIL - Range Partitioning (Also Covered) ---
test_fail_range_partitioned {
    result == "fail" with input as {
        "type": "google_bigquery_table",
        "name": "projects/p1/datasets/d1/tables/id_ranges",
        "properties": {
            "rangePartitioning": { "field": "customer_id" },
            # Missing "requirePartitionFilter" implies false -> FAIL
        }
    }
}
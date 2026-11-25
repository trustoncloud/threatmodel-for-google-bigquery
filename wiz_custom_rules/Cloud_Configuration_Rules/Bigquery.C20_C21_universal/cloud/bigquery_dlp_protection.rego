package wiz

# --- Logic ---
default result := "pass"

# Universal baseline: a DLP trigger that scans BigQuery must run and carry
# inspection rules, either an inspect template or an inline inspect_config.
# The rule reads the scan's inspection rules and status only. It does not
# show that data was redacted, or that every sensitive table has a trigger.

inspect_job := input.Job.InspectJob

# storage_config.Type holds one of BigQueryOptions, CloudStorageOptions,
# DatastoreOptions or HybridOptions.
targets_bigquery {
    is_object(inspect_job.storage_config.Type.BigQueryOptions)
}

# An unset template arrives as "".
carries_inspection_rules {
    object.get(inspect_job, "inspect_template_name", "") != ""
}

# An unset inspect_config is absent.
carries_inspection_rules {
    is_object(inspect_job.inspect_config)
}

fail_no_rules {
    not carries_inspection_rules
}

# status is the enum as an integer: 1 HEALTHY, 2 PAUSED, 3 CANCELLED. An
# unspecified status (0) arrives as no field. Only a HEALTHY trigger runs.
status := object.get(input, "status", 0)

status_names := {0: "STATUS_UNSPECIFIED", 1: "HEALTHY", 2: "PAUSED", 3: "CANCELLED"}

status_label := object.get(status_names, status, sprintf("%v", [status]))

is_healthy {
    status == 1
}

is_healthy {
    status == "HEALTHY"
}

fail_status {
    not is_healthy
}

# --- Aggregation ---
result := "skip" {
    not is_object(inspect_job)
} else := "skip" {
    not targets_bigquery
} else := "fail" {
    fail_no_rules
} else := "fail" {
    fail_status
}

# --- Metadata ---
issues[msg] {
    fail_no_rules
    msg := "the trigger scans BigQuery with no inspect template and no inline inspect_config"
}

issues[msg] {
    fail_status
    msg := sprintf("status is %v, so the trigger does not scan", [status_label])
}

currentConfiguration := sprintf("Issues found: %v", [concat("; ", sort([m | m := issues[_]]))]) {
    result == "fail"
} else := "The trigger is HEALTHY and carries inspection rules."

expectedConfiguration := "DLP triggers that scan BigQuery must be HEALTHY and set an inspect template or an inline inspect_config. This checks the scan's inspection rules and status only, not that data was redacted or that every sensitive table is scanned."

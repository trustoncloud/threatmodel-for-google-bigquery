package wiz

# The label records the backup schedule a dataset is meant to have. Snapshots
# and exports are separate resources, absent from the dataset payload, so the
# rule does not show that a backup exists, ran or can be restored. Tables and
# models are not checked.

# --- Configuration ---
# Allowlist: the label that names a dataset's backup schedule.
# Example: "backup_policy" label must exist, and its value must be one of the allowed schedules.
backup_label_key := "backup_policy"

authorized_backup_schedules := {
    "daily",
    "weekly",
    "dr_critical",
    "legal_hold"
}

# --- Logic ---
default result := "pass"

# Dataset labels arrive as the top-level labels map, absent when none are set.
resource_labels := object.get(input, "labels", {})
actual_schedule := object.get(resource_labels, backup_label_key, null)

# Fail if the label is missing entirely
fail_missing_label {
    actual_schedule == null
}

# Fail if the label exists but has an invalid value (e.g. "none" or "temp")
fail_invalid_schedule {
    actual_schedule != null
    not authorized_backup_schedules[actual_schedule]
}

result := "skip" {
    not input.datasetReference
} else := "fail" {
    fail_missing_label
} else := "fail" {
    fail_invalid_schedule
}

# --- Metadata ---
currentConfiguration := sprintf("Backup label '%v' is not set", [backup_label_key]) {
    result == "fail"
    fail_missing_label
} else := sprintf("Backup label '%v' is '%v', which is not an approved schedule", [backup_label_key, actual_schedule]) {
    result == "fail"
} else := sprintf("Backup label '%v' records the schedule '%v'. The label does not show that a backup exists or can be restored", [backup_label_key, actual_schedule]) {
    result == "pass"
} else := "Backup configuration is missing"

expectedConfiguration := sprintf("Dataset must have the '%v' label set to one of: %v. The label records the intended backup schedule only: it does not show that a backup exists, ran or can be restored, and tables and models are not checked.", [backup_label_key, authorized_backup_schedules])

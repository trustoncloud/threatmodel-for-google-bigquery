package wiz

# Note: As BigQuery snapshots are separate resources not visible in dataset properties, Rego cannot directly verify their existence.
# This control serves as a governance check, validating that the dataset is labeled for inclusion in the authorized backup strategy.

# --- Configuration ---
# Allowlist: Define the required labels that indicate a dataset is being backed up.
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
currentConfiguration := sprintf("Backup label '%v' is set to: '%v'", [backup_label_key, actual_schedule]) {
    result != "skip"
} else := "Backup configuration is missing"

expectedConfiguration := sprintf("Dataset must have the '%v' label set to one of: %v", [backup_label_key, authorized_backup_schedules])

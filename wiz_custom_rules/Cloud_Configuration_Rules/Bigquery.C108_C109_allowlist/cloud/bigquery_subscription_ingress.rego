package wiz

# --- Configuration ---
# 1. Authorized External Sources (Allowlist)
# A list of Regex patterns matched against "projects/{projectNumber}/datasets/{datasetId}".
# NOTE: the API reports the source project as a project NUMBER, not a project ID.
authorized_source_dataset_patterns := {
    # Example: Allow a specific partner project (by project number)
    "^projects/123456789012/datasets/sales_data_shared$",

    # Example: Allow any dataset from an authorized project number
    "^projects/987654321098/datasets/.*$"
}

# 2. (Optional) Internal Project Exclusion
# Auto-pass links from your own project numbers.
internal_project_pattern := "^projects/(111111111111|222222222222)/datasets/.*$"

# --- Logic ---
default result := "pass"

# 1. Identify Linked Datasets (Subscriptions)
# A dataset is a "Subscription" if it has a 'linkedDatasetSource' property.
# sourceDataset is a reference object {projectId, datasetId}, where projectId
# carries the source project NUMBER.
get_source_dataset = src {
    ref := input.linkedDatasetSource.sourceDataset
    src := sprintf("projects/%v/datasets/%v", [ref.projectId, ref.datasetId])
}

# Helper: Check if Source is Allowed
is_source_allowed(src) {
    # Check Allowlist
    pattern := authorized_source_dataset_patterns[_]
    regex.match(pattern, src)
} else {
    # Check Internal Pattern (Auto-allow internal links)
    regex.match(internal_project_pattern, src)
}

# Failure: Subscription to an Unauthorized Source
fail_unauthorized_subscription {
    src := get_source_dataset

    # Fail if the source matches NONE of the allowed patterns
    not is_source_allowed(src)
}

# --- Aggregation ---
result := "skip" {
    not input.datasetReference
} else := "fail" {
    fail_unauthorized_subscription
}

# --- Metadata ---
currentConfiguration := sprintf("Dataset is subscribed to source: '%v'", [get_source_dataset]) {
    fail_unauthorized_subscription
} else := "Subscription source is authorized (or dataset is native)"

expectedConfiguration := "Linked Datasets must point to authorized source datasets (Allowlist)."

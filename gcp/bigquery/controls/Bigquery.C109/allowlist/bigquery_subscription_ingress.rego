package wiz

# --- Configuration ---
# 1. Authorized External Sources (Allowlist)
# A list of Regex patterns for the 'sourceDataset' reference.
# Format: "projects/{project_id}/datasets/{dataset_id}"
allowed_subscription_sources := {
    # Example: Allow Google Public Data
    "^projects/bigquery-public-data/datasets/.*$",
    
    # Example: Allow a specific Partner's dataset
    "^projects/partner-prod-123/datasets/sales_data_shared$"
}

# 2. (Optional) Internal Project Exclusion
# If your org uses Linked Datasets internally (Project A -> Project B), 
# you might want to auto-pass them if they match your Org ID pattern.
internal_project_pattern := "^projects/my-org-.*$"

# --- Logic ---
default result := "pass"

is_dataset { input.type == "google_bigquery_dataset" }

# 1. Identify Linked Datasets (Subscriptions)
# A dataset is a "Subscription" if it has a 'linkedDatasetSource' property.
get_source_dataset = src {
    src := input.properties.linkedDatasetSource.sourceDataset
    src != null
}

# Helper: Check if Source is Allowed
is_source_allowed(src) {
    # Check Allowlist
    pattern := allowed_subscription_sources[_]
    regex.match(pattern, src)
} else {
    # Check Internal Pattern (Auto-allow internal links)
    regex.match(internal_project_pattern, src)
}

# Failure: Subscription to an Unauthorized Source
fail_unauthorized_subscription {
    is_dataset
    src := get_source_dataset
    
    # Fail if the source matches NONE of the allowed patterns
    not is_source_allowed(src)
}

# --- Aggregation ---
result := "skip" {
    not is_dataset
} else := "fail" {
    fail_unauthorized_subscription
}

# --- Metadata ---
current_source := object.get(input.properties, "linkedDatasetSource", {}).sourceDataset

currentConfiguration := sprintf("Dataset is subscribed to source: '%v'", [current_source]) {
    fail_unauthorized_subscription
} else := "Subscription source is authorized (or dataset is native)"

expectedConfiguration := "Linked Datasets must point to authorized source datasets (Allowlist)."
package wiz

# --- Configuration ---
allowed_source_ids := {
    "google_cloud_storage",
    "scheduled_query"
}

allowed_destination_datasets := {
    "raw_ingestion_zone",
    "my_governed_dataset"
}

# Allowlist of Service Accounts authorized to RUN transfers
allowed_service_accounts := {
    "etl-loader@my-project.iam.gserviceaccount.com",
    "backup-admin@my-project.iam.gserviceaccount.com"
}

# --- Logic ---
default result := "pass"

is_transfer_config { input.type == "google_bigquery_datatransfer_config" }

# 1. Check Source ID
fail_unauthorized_source_type {
    is_transfer_config
    not allowed_source_ids[input.properties.dataSourceId]
}

# 2. Check Destination Dataset
fail_unauthorized_destination {
    is_transfer_config
    not allowed_destination_datasets[input.properties.destinationDatasetId]
}

# 3. Check Service Account Identity (Privilege Escalation Protection)
# If serviceAccountName is set, it must be in our allowlist.
fail_unauthorized_identity {
    is_transfer_config
    # specific service account used (if null, it uses user identity, which is safer)
    sa_name := object.get(input.properties, "serviceAccountName", "")
    sa_name != ""
    not allowed_service_accounts[sa_name]
}

# 4. Check GCS Specific Constraints
fail_bad_gcs_params {
    is_transfer_config
    input.properties.dataSourceId == "google_cloud_storage"
    
    params := object.get(input.properties, "params", {})
    
    # CHECK A: Path must start with trusted bucket (Corrected field: data_path_template)
    path := object.get(params, "data_path_template", "")
    not startswith(path, "gs://trusted-corp-")
}

fail_destructive_action {
    is_transfer_config
    input.properties.dataSourceId == "google_cloud_storage"
    
    params := object.get(input.properties, "params", {})
    
    # CHECK B: Destructive deletion must be FALSE
    # Params are strings "true"/"false"
    delete_files := object.get(params, "delete_source_files", "false")
    delete_files == "true"
}

# --- Aggregation ---
result := "skip" {
    not is_transfer_config
} else := "fail" {
    fail_unauthorized_source_type
} else := "fail" {
    fail_unauthorized_destination
} else := "fail" {
    fail_unauthorized_identity
} else := "fail" {
    fail_bad_gcs_params
} else := "fail" {
    fail_destructive_action
}

# --- Metadata ---
currentConfiguration := sprintf("Issues found: Source=%v, Dest=%v, SA=%v, Delete=%v", [
    input.properties.dataSourceId, 
    input.properties.destinationDatasetId,
    object.get(input.properties, "serviceAccountName", "default"),
    object.get(input.properties.params, "delete_source_files", "false")
]) {
    result == "fail"
} else := "Transfer configuration is authorized"

expectedConfiguration := "Transfers must use authorized Sources, Destinations, Identities, and non-destructive parameters."
package wiz

# --- Configuration ---
authorized_data_source_ids := {
    "google_cloud_storage",
    "scheduled_query"
}

authorized_destination_datasets := {
    "raw_ingestion_zone",
    "my_governed_dataset"
}

# Allowlist of identities (users or service accounts) authorized to RUN transfers
authorized_transfer_identities := {
    "etl-loader@my-project.iam.gserviceaccount.com",
    "backup-admin@my-project.iam.gserviceaccount.com"
}

# Trusted GCS path prefixes for storage-based transfers
authorized_gcs_path_prefixes := {
    "gs://trusted-corp-"
}

# --- Logic ---
default result := "pass"

# Transfer configs use snake_case fields and carry the full path in name.
is_transfer_config {
    contains(object.get(input, "name", ""), "/transferConfigs/")
}

# The destination dataset sits inside the Destination oneof wrapper.
destination_dataset := object.get(object.get(input, "Destination", {}), "DestinationDatasetId", "")

# params is a protobuf Struct: params.fields.<key>.Kind.StringValue / BoolValue.
param_string(key) := val {
    val := input.params.fields[key].Kind.StringValue
} else := ""

param_bool(key) := val {
    val := input.params.fields[key].Kind.BoolValue
} else := false

# 1. Check Source ID
fail_unauthorized_source_type {
    not authorized_data_source_ids[object.get(input, "data_source_id", "")]
}

# 2. Check Destination Dataset
fail_unauthorized_destination {
    not authorized_destination_datasets[destination_dataset]
}

# 3. Check Run Identity (Privilege Escalation Protection)
# The resource exposes the identity at owner_info.email; the write-only
# serviceAccountName request parameter never appears on the resource.
fail_unauthorized_identity {
    owner := object.get(object.get(input, "owner_info", {}), "email", "")
    owner != ""
    not authorized_transfer_identities[owner]
}

# 4. GCS-specific: source path must start with a trusted prefix
fail_bad_gcs_params {
    object.get(input, "data_source_id", "") == "google_cloud_storage"
    path := param_string("data_path_template")
    prefixes_matching := {p | p := authorized_gcs_path_prefixes[_]; startswith(path, p)}
    count(prefixes_matching) == 0
}

# 5. GCS-specific: destructive source deletion must be disabled
fail_destructive_action {
    object.get(input, "data_source_id", "") == "google_cloud_storage"
    param_bool("delete_source_files") == true
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
currentConfiguration := sprintf("Issues found: Source=%v, Dest=%v, Identity=%v, Delete=%v", [
    object.get(input, "data_source_id", ""),
    destination_dataset,
    object.get(object.get(input, "owner_info", {}), "email", "default"),
    param_bool("delete_source_files")
]) {
    result == "fail"
} else := "Transfer configuration is authorized"

expectedConfiguration := "Transfers must use authorized Sources, Destinations, Identities, and non-destructive parameters."

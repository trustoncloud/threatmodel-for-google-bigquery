package wiz

# --- Configuration ---
# Universal Policy:
# All projects must have Fine-Grained ACLs enabled (required for Row-Level Security).
# No other configuration is needed.

# --- Logic ---
default result := "pass"

# Target: BigQuery Project Service Config
is_project_config {
    # Adjust type based on Wiz schema mapping
    input.type == "google_bigquery_project_service_config"
}

# Helper: Get ACL Option
# Defaults to false if missing (Fail Secure)
is_acls_enabled {
    input.properties.enableFineGrainedDatasetAclsOption == true
}

# Failure: ACLs are disabled
fail_security_feature_disabled {
    is_project_config
    not is_acls_enabled
}

# --- Aggregation ---
result := "skip" {
    not is_project_config
} else := "fail" {
    fail_security_feature_disabled
}

# --- Metadata ---
currentConfiguration := "Fine-Grained ACLs are DISABLED" {
    fail_security_feature_disabled
} else := "Fine-Grained ACLs are ENABLED"

expectedConfiguration := "All BigQuery Projects must have 'enableFineGrainedDatasetAclsOption' set to true."
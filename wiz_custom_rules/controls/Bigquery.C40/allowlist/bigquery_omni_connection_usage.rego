package wiz

# --- Configuration ---
# Define which clouds are authorized for Omni connections.
# Empty set {} means NO Omni connections are allowed.
authorized_omni_clouds := {
    # "AWS",   <-- Uncomment to allow AWS
    # "AZURE"  <-- Uncomment to allow Azure
}

# --- Logic ---
default result := "pass"

is_connection { input.type == "google_bigquery_connection" }

# 1. Identify Connection Type
# We look for the existence of specific property blocks
connection_type := "AWS" {
    object.get(input.properties, "aws", null) != null
} else := "AZURE" {
    object.get(input.properties, "azure", null) != null
} else := "GCP" {
    # Native GCP connections (Safe)
    object.get(input.properties, "cloudResource", null) != null
} else := "GCP" {
    object.get(input.properties, "cloudSql", null) != null
} else := "GCP" {
    object.get(input.properties, "cloudSpanner", null) != null
} else := "OTHER"

# 2. Compliance Check
fail_unauthorized_omni {
    is_connection
    # Logic: If it is an Omni connection (AWS/Azure) AND not in the allowlist
    connection_type != "GCP"
    connection_type != "OTHER"
    
    # Check against allowlist
    not authorized_omni_clouds[connection_type]
}

result := "skip" {
    not is_connection
} else := "fail" {
    fail_unauthorized_omni
}

# --- Metadata ---
currentConfiguration := sprintf("Connection uses unauthorized cloud: '%v'", [connection_type]) {
    fail_unauthorized_omni
} else := sprintf("Connection type '%v' is authorized", [connection_type])

expectedConfiguration := sprintf("BigQuery Omni connections must match the authorized cloud list: %v", [authorized_omni_clouds])
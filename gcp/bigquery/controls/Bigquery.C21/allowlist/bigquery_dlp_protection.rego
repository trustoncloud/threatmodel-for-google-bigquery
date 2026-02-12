package wiz

# --- Configuration ---
# Allowlist: We strictly require specific Managed Templates.
# Inline configurations (inspectConfig) are considered UNAUTHORIZED here.
authorized_templates := {
    "projects/my-project/inspectTemplates/strict-pii-v1",
    "projects/my-project/inspectTemplates/finance-pci-v1"
}

default result := "pass"

template_name := input.properties.inspectJob.inspectTemplateName

targets_bigquery {
    input.properties.inspectJob.storageConfig.bigQueryOptions
}

is_authorized {
    authorized_templates[template_name]
}

result := "skip" {
    not targets_bigquery
} else := "fail" {
    # This fails if template is missing OR if template is wrong
    not is_authorized
}

# --- Metadata ---
currentConfiguration := sprintf("Unauthorized DLP configuration. Template: '%v'", [template_name]) {
    result == "fail"
} else := "Authorized DLP template configured"

expectedConfiguration := sprintf("BigQuery DLP Job Triggers must use one of the authorized templates: %v", [authorized_templates])
package wiz

default result := "pass"

# Check for a specific template reference
has_template_ref {
    input.properties.inspectJob.inspectTemplateName != ""
}

# Check for inline configuration (custom rules)
has_inline_config {
    input.properties.inspectJob.inspectConfig
}

# Verify it targets BigQuery
targets_bigquery {
    input.properties.inspectJob.storageConfig.bigQueryOptions
}

result := "skip" {
    not targets_bigquery
} else := "fail" {
    # Fail only if BOTH are missing
    not has_template_ref
    not has_inline_config
}

# --- Metadata ---
currentConfiguration := "DLP Job Trigger has no inspection rules (Template or Inline)" {
    result == "fail"
} else := "DLP Job Trigger is configured to scan BigQuery"

expectedConfiguration := "BigQuery DLP Job Triggers must have inspection rules configured."
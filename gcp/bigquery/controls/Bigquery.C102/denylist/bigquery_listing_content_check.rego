package wiz

# --- Configuration ---
# List of Regex patterns to detect sensitive data in Listing metadata.
# Adjust these based on your DLP requirements.
sensitive_patterns := {
    # 1. Potential Secrets
    "AIza[0-9A-Za-z\\-_]{35}",     # Google API Key
    "AKIA[0-9A-Z]{16}",            # AWS Access Key
    
    # 2. PII (e.g., Email Addresses)
    "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
    
    # 3. Sensitive Keywords
    "(?i)password\\s*[:=]\\s*\\S+", # "password = ..."
    "(?i)secret\\s*[:=]\\s*\\S+",   # "secret : ..."
    "(?i)SSN\\s*[:=]\\s*\\d+"       # "SSN : 123..."
}

# Fields to inspect
target_fields := {"displayName", "description", "documentation"}

# --- Logic ---
default result := "pass"

is_listing { input.type == "google_bigquery_analytics_hub_listing" }

# Helper: Get value of a specific field
get_field_value(field_name) = val {
    val := object.get(input.properties, field_name, "")
}

# Check for matches
fail_sensitive_content[msg] {
    is_listing
    
    # Iterate over target fields
    field := target_fields[_]
    val := get_field_value(field)
    val != ""
    
    # Iterate over patterns
    pattern := sensitive_patterns[_]
    
    # Check match
    regex.match(pattern, val)
    
    msg := sprintf("Sensitive data found in field '%v' (Matched pattern: '%v')", [field, pattern])
}

# --- Aggregation ---
result := "skip" {
    not is_listing
} else := "fail" {
    count(fail_sensitive_content) > 0
}

# --- Metadata ---
currentConfiguration := concat("; ", fail_sensitive_content) {
    result == "fail"
} else := "No sensitive data detected in listing fields"

expectedConfiguration := "Listing fields (Description, Documentation) must not contain sensitive data (Secrets, PII, etc)."
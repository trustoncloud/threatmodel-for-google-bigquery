package wiz

# --- Configuration ---
# Regex patterns for sensitive data that must not appear in listing metadata.
# Keep in sync with the Terraform matcher.
sensitive_patterns := {
    "AIza[0-9A-Za-z\\-_]{35}",     # Google API Key
    "AKIA[0-9A-Z]{16}",            # AWS Access Key
    "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",  # Email address
    "(?i)password\\s*[:=]\\s*\\S+",
    "(?i)secret\\s*[:=]\\s*\\S+",
    "(?i)SSN\\s*[:=]\\s*\\d+"
}

# Listing attributes to inspect
target_fields := {"display_name", "description", "documentation"}

# --- Logic ---
default result := "pass"

# A listing name ends in /dataExchanges/<exchange>/listings/<listing>.
is_listing {
    regex.match(`^projects/[^/]+/locations/[^/]+/dataExchanges/[^/]+/listings/[^/]+$`, object.get(input, "name", ""))
}

# A field left out arrives as an empty string. The finding names the field and
# the pattern, never the matched text.
sensitive_fields[field] {
    field := target_fields[_]
    val := input[field]
    is_string(val)
    val != ""
    regex.match(sensitive_patterns[_], val)
}

# --- Aggregation ---
result := "skip" {
    not is_listing
} else := "fail" {
    count(sensitive_fields) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Listing field(s) hold text that matches a sensitive data pattern: %v", [concat(", ", sort(sensitive_fields))]) {
    result == "fail"
} else := "Listing display name, description and documentation match no sensitive data pattern"

expectedConfiguration := "The display name, description and documentation of a listing must not hold text that matches a pattern in sensitive_patterns (API keys, access keys, email addresses, passwords, secrets, SSNs)."

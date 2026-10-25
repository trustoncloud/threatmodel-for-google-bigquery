package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Regex patterns for sensitive data that must not appear in listing metadata.
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
# Finding: sensitive content in a listing metadata field.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    field := target_fields[_]
    val := object.get(l, field, "")
    val != ""
    pattern := sensitive_patterns[_]
    regex.match(pattern, val)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].%s", [name, field]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "listing metadata must not contain sensitive data (secrets, PII)",
        "keyActualValue": sprintf("field '%v' matches a sensitive-data pattern", [field]),
        "resourceTags": object.get(l, "labels", {}),
    }
}

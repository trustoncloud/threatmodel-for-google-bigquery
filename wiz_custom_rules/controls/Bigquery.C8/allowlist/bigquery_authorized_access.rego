package wiz

# --- Configuration ---
# Allowlist: Define the exact set of authorized entities.
# Keys must match the format: "prefix:value"
authorized_entities := {
    "specialGroup:projectOwners",
    "group:data-team@example.com",
    "user:admin@example.com"
}

# --- Logic ---
default result := "pass"

access_list := input.properties.access

# Helper to normalize entity strings for comparison
get_entity(entry) := val {
    val := sprintf("user:%v", [entry.userByEmail])
} else := val {
    val := sprintf("group:%v", [entry.groupByEmail])
} else := val {
    val := sprintf("domain:%v", [entry.domain])
} else := val {
    val := sprintf("specialGroup:%v", [entry.specialGroup])
} else := val {
    val := entry.iamMember # iamMember usually includes the prefix
} else := val {
    val := sprintf("view:%v", [entry.view.tableId])
}

# Identify any entity in the access list that is NOT in the authorized set
unauthorized_findings[entity] {
    entry := access_list[_]
    entity := get_entity(entry)
    not authorized_entities[entity]
}

result := "skip" {
    not input.properties
} else := "skip" {
    object.get(input.properties, "access", null) == null
} else := "fail" {
    count(unauthorized_findings) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Unauthorized entities found in dataset ACL: %v", [unauthorized_findings]) {
    result == "fail"
} else := "All dataset access entities are authorized"

expectedConfiguration := "Only authorized IAM entities must have access to the BigQuery dataset."
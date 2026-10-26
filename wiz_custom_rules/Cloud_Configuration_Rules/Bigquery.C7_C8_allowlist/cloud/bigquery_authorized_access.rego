package wiz

# --- Configuration ---
# Allowlist: Define the exact set of authorized entities.
# Keys must match the format: "prefix:value"
authorized_entities := {
    "specialGroup:projectOwners",
    "specialGroup:projectWriters",
    "specialGroup:projectReaders",
    "group:data-admins@yourcompany.com",
    "group:data-team@yourcompany.com",
    "user:admin@yourcompany.com"
}

# --- Logic ---
default result := "pass"

access_list := object.get(input, "access", [])

# Normalize entity strings for comparison. Unset string fields arrive as ""
# (not absent), so every branch requires a non-empty value; view/routine/
# dataset grants arrive as nested objects only when present.
get_entity(entry) := val {
    e := object.get(entry, "userByEmail", "")
    e != ""
    val := sprintf("user:%v", [e])
} else := val {
    e := object.get(entry, "groupByEmail", "")
    e != ""
    val := sprintf("group:%v", [e])
} else := val {
    e := object.get(entry, "domain", "")
    e != ""
    val := sprintf("domain:%v", [e])
} else := val {
    e := object.get(entry, "specialGroup", "")
    e != ""
    val := sprintf("specialGroup:%v", [e])
} else := val {
    e := object.get(entry, "iamMember", "")
    e != ""
    val := e # iamMember includes the prefix
} else := val {
    val := sprintf("view:%v", [entry.view.tableId])
} else := val {
    val := sprintf("routine:%v", [entry.routine.routineId])
} else := val {
    val := sprintf("dataset:%v", [entry.dataset.dataset.datasetId])
}

# Identify any entity in the access list that is NOT in the authorized set
unauthorized_findings[entity] {
    entry := access_list[_]
    entity := get_entity(entry)
    not authorized_entities[entity]
}

result := "skip" {
    not input.datasetReference
} else := "skip" {
    count(access_list) == 0
} else := "fail" {
    count(unauthorized_findings) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Unauthorized entities found in dataset ACL: %v", [unauthorized_findings]) {
    result == "fail"
} else := "All dataset access entities are authorized"

expectedConfiguration := "Only authorized IAM entities must have access to the BigQuery dataset."

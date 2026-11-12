package wiz

# --- Configuration ---
# Allowlist: Define the exact set of authorized entities.
# Keys must match the format: "prefix:value"
# A service account is written "user:<email>", the way the dataset access
# list files it.
# An authorized view, routine or dataset is written with its project ID,
# dataset and ID: "view:<project-id>.<dataset>.<table>",
# "routine:<project-id>.<dataset>.<routine>", "dataset:<project-id>.<dataset>".
authorized_entities := {
    "specialGroup:projectOwners",
    "specialGroup:projectWriters",
    "specialGroup:projectReaders",
    "group:data-admins@yourcompany.com",
    "group:data-team@yourcompany.com",
    "user:admin@yourcompany.com",
    "user:etl-loader@my-project.iam.gserviceaccount.com",
    "view:my-project.reporting.sales_summary",
    "routine:my-project.reporting.mask_email",
    "dataset:my-project.reporting"
}

# --- Logic ---
default result := "pass"

access_list := object.get(input, "access", [])

# Normalize entity strings for comparison. Unset string fields arrive as ""
# (not absent), so every branch requires a non-empty value; view/routine/
# dataset grants arrive as nested objects only when present. Each is named by
# project, dataset and ID together, so the same ID elsewhere is a different
# entity. A reference that carries no project or dataset matches no entry.
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
    v := entry.view
    val := sprintf("view:%v.%v.%v", [object.get(v, "projectId", ""), object.get(v, "datasetId", ""), v.tableId])
} else := val {
    r := entry.routine
    val := sprintf("routine:%v.%v.%v", [object.get(r, "projectId", ""), object.get(r, "datasetId", ""), r.routineId])
} else := val {
    d := entry.dataset.dataset
    val := sprintf("dataset:%v.%v", [object.get(d, "projectId", ""), d.datasetId])
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

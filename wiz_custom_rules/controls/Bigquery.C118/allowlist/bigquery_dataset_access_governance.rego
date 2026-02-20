package wiz

# --- Configuration ---
# 1. Authorized Domains
authorized_domains := {
    "yourcompany.com",
    "subsidiary.com",
    "gserviceaccount.com"
}

# 2. Block Public Access
blocked_special_groups := {"allUsers", "allAuthenticatedUsers"}

# 3. Mandatory Access Entities (Drift Detection)
# We enable this rule to ensure specific groups are always present.
required_entities := {
    # REQUIRED: Central Data Admin Group must always be OWNER
    { "role": "OWNER", "type": "groupByEmail", "value": "data-admins@yourcompany.com" }
}

# --- Logic ---
default result := "pass"

is_dataset { input.type == "google_bigquery_dataset" }

access_entries := object.get(input.properties, "access", [])

# --- Check 1: Unauthorized Entities ---
get_entity_email(entry) = email {
    email := entry.userByEmail
} else = email {
    email := entry.groupByEmail
} else = email {
    startswith(entry.iamMember, "user:")
    parts := split(entry.iamMember, ":")
    email := parts[1]
} else = email {
    startswith(entry.iamMember, "serviceAccount:")
    parts := split(entry.iamMember, ":")
    email := parts[1]
} else = email {
    startswith(entry.iamMember, "group:")
    parts := split(entry.iamMember, ":")
    email := parts[1]
}

fail_public_access[msg] {
    is_dataset
    entry := access_entries[_]
    group := object.get(entry, "specialGroup", "")
    blocked_special_groups[group]
    msg := sprintf("Unauthorized Access: Public group '%v' found with role '%v'", [group, entry.role])
}

fail_unauthorized_domain[msg] {
    is_dataset
    entry := access_entries[_]
    email := get_entity_email(entry)
    # Check if email ends with any authorized domain
    allowed := { d | d := authorized_domains[_]; endswith(email, d) }
    count(allowed) == 0
    msg := sprintf("Unauthorized Access: Entity '%v' belongs to an unauthorized domain", [email])
}

# --- Check 2: Missing Mandatory Entities (Drift) ---
has_required_entity(req) {
    entry := access_entries[_]
    entry.role == req.role
    object.get(entry, req.type, "") == req.value
}

fail_missing_mandatory_entity[msg] {
    is_dataset
    req := required_entities[_]
    not has_required_entity(req)
    msg := sprintf("Drift Detected: Mandatory entity '%v' (%v) with role '%v' is missing", [req.value, req.type, req.role])
}

# --- Aggregation ---
result := "skip" {
    not is_dataset
} else := "fail" {
    count(fail_public_access) > 0
} else := "fail" {
    count(fail_unauthorized_domain) > 0
} else := "fail" {
    count(fail_missing_mandatory_entity) > 0
}

# --- Metadata ---
# Union sets first (|) then cast to array
all_failures := (fail_public_access | fail_unauthorized_domain) | fail_missing_mandatory_entity

currentConfiguration := concat("; ", [ m | m := all_failures[_] ]) {
    result == "fail"
} else := "Dataset access entities are authorized and compliant"

expectedConfiguration := "Dataset 'access' list must only contain authorized domains and must include mandatory admin groups."
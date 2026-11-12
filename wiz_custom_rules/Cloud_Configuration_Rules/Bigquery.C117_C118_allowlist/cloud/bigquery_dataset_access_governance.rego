package wiz

# --- Configuration ---
# 1. Who may hold access on a dataset.
#    domains: users, groups and domain-wide grants. "yourcompany.com" matches
#      only that domain; add "*.yourcompany.com" to approve its subdomains.
#    emails: single users or groups, by exact address.
#    service_accounts: single service accounts, by exact address. Google's
#      service agents (service-<number>@gcp-sa-...) are approved only this way.
#    project_ids: every service account created in these projects.
#    project_numbers: the default Compute Engine and Google APIs accounts of
#      these projects.
#    members: exact access members of any other kind. The three project groups
#      are the entries BigQuery adds to every dataset.
#    A domain never approves a service account.
authorized_access := {
    "domains": ["yourcompany.com", "subsidiary.com"],
    "emails": [],
    "service_accounts": [],
    "project_ids": ["my-project"],
    "project_numbers": [],
    "members": [
        "specialGroup:projectOwners",
        "specialGroup:projectWriters",
        "specialGroup:projectReaders"
    ]
}

# 2. Block Public Access
blocked_public_members := {"allUsers", "allAuthenticatedUsers"}

# 3. Mandatory Access Entities (Drift Detection)
# We enable this rule to ensure specific groups are always present.
required_entities := {
    # REQUIRED: Central Data Admin Group must always be OWNER
    { "role": "OWNER", "type": "groupByEmail", "value": "data-admins@yourcompany.com" }
}

# --- Logic ---
default result := "pass"

access_entries := object.get(input, "access", [])

# --- Check 1: Unauthorized Entities ---
# Public access arrives as a special group or as a bare IAM member.
entry_is_public(entry) {
    blocked_public_members[object.get(entry, "specialGroup", "")]
}

entry_is_public(entry) {
    blocked_public_members[object.get(entry, "iamMember", "")]
}

fail_public_access[msg] {
    entry := access_entries[_]
    entry_is_public(entry)
    msg := sprintf("Unauthorized Access: Public member '%v' found with role '%v'", [tocm_bq_access_member(entry), object.get(entry, "role", "")])
}

# Entries for authorized views, routines and datasets carry no member and are
# not judged here.
fail_unauthorized_member[msg] {
    entry := access_entries[_]
    not entry_is_public(entry)
    member := tocm_bq_access_member(entry)
    not tocm_member_allowed(member, authorized_access)
    msg := sprintf("Unauthorized Access: '%v' is not an approved member", [member])
}

# --- Check 2: Missing Mandatory Entities (Drift) ---
# A grant with a condition holds only while the condition does, so it does not
# count as the mandatory grant. Its entry carries the condition inside the
# role, as "<role>_withcond_<id>", so it never equals the required role.
has_required_entity(req) {
    entry := access_entries[_]
    entry.role == req.role
    object.get(entry, req.type, "") == req.value
}

# The required entity holds a grant, but only under a condition.
has_conditional_grant(req) {
    entry := access_entries[_]
    object.get(entry, req.type, "") == req.value
    regex.match(`_withcond_[0-9A-Za-z]+$`, object.get(entry, "role", ""))
}

fail_missing_mandatory_entity[msg] {
    req := required_entities[_]
    not has_required_entity(req)
    not has_conditional_grant(req)
    msg := sprintf("Drift Detected: Mandatory entity '%v' (%v) with role '%v' is missing", [req.value, req.type, req.role])
}

fail_missing_mandatory_entity[msg] {
    req := required_entities[_]
    not has_required_entity(req)
    has_conditional_grant(req)
    msg := sprintf("Drift Detected: Mandatory entity '%v' (%v) holds a grant only under a condition, which does not count as role '%v'", [req.value, req.type, req.role])
}

# --- Aggregation ---
result := "skip" {
    not input.datasetReference
} else := "fail" {
    count(fail_public_access) > 0
} else := "fail" {
    count(fail_unauthorized_member) > 0
} else := "fail" {
    count(fail_missing_mandatory_entity) > 0
}

# --- Metadata ---
# Union sets first (|) then cast to array
all_failures := (fail_public_access | fail_unauthorized_member) | fail_missing_mandatory_entity

currentConfiguration := concat("; ", [ m | m := all_failures[_] ]) {
    result == "fail"
} else := "Dataset access members are approved and the mandatory admin groups are present"

expectedConfiguration := "The dataset's access list must hold only approved users, groups, domains and service accounts (a service account by exact address or approved project), no public member, and every mandatory admin group. Access inherited from the project, folder or organization is not on the dataset and is not checked. A condition on an access entry is not read, so a conditional grant to a mandatory admin group counts as present."

# --- Matching helpers ---
# --- toc-match begin: email v1 ---
# Lowercased domain of an email with exactly one "@" and a non-empty local part.
tocm_email_domain(email) := d {
    is_string(email)
    parts := split(lower(trim_space(email)), "@")
    count(parts) == 2
    parts[0] != ""
    d := trim_suffix(parts[1], ".")
    d != ""
}

tocm_is_sa_domain(d) {
    d == "gserviceaccount.com"
}

tocm_is_sa_domain(d) {
    endswith(d, ".gserviceaccount.com")
}

# A domain matches an entry only by equality. An entry "*.corp.com" admits
# subdomains of corp.com across a "." boundary, never corp.com itself, so list
# both when both are wanted. Service-account domains never match a domain
# entry; service accounts go through tocm_sa_allowed.
tocm_domain_allowed(domain, allowed) {
    is_string(domain)
    d := lower(trim_suffix(trim_space(domain), "."))
    not tocm_is_sa_domain(d)
    entry := lower(trim_space(allowed[_]))
    not startswith(entry, "*.")
    d == entry
}

tocm_domain_allowed(domain, allowed) {
    is_string(domain)
    d := lower(trim_suffix(trim_space(domain), "."))
    not tocm_is_sa_domain(d)
    entry := lower(trim_space(allowed[_]))
    startswith(entry, "*.")
    suffix := substring(entry, 1, -1)
    count(d) > count(suffix)
    endswith(d, suffix)
}

# A user or group email: listed exactly, or its domain is allowed.
tocm_email_allowed(email, allowed_emails, _) {
    is_string(email)
    lower(trim_space(email)) == lower(trim_space(allowed_emails[_]))
}

tocm_email_allowed(email, _, allowed_domains) {
    tocm_domain_allowed(tocm_email_domain(email), allowed_domains)
}

tocm_sa_email(sa) := e {
    is_string(sa)
    e := lower(trim_prefix(trim_space(sa), "serviceAccount:"))
}

# Project ID of a user-managed (name@PROJECT_ID.iam.gserviceaccount.com) or
# App Engine default (PROJECT_ID@appspot.gserviceaccount.com) service account.
tocm_sa_project_id(sa) := p {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    parts[0] != ""
    endswith(parts[1], ".iam.gserviceaccount.com")
    p := trim_suffix(parts[1], ".iam.gserviceaccount.com")
    regex.match(`^[a-z][a-z0-9-]{4,28}[a-z0-9]$`, p)
}

tocm_sa_project_id(sa) := p {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    parts[1] == "appspot.gserviceaccount.com"
    p := parts[0]
    regex.match(`^[a-z][a-z0-9-]{4,28}[a-z0-9]$`, p)
}

# Project number of the Compute Engine default, Google APIs and legacy Cloud
# Build accounts, whose domains only Google can issue. Service agents
# (service-N@gcp-sa-*.iam.gserviceaccount.com and similar) are not read here:
# their shapes vary and a user-managed account can imitate them, so list them
# by exact email.
tocm_sa_project_number(sa) := n {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    parts[1] == "developer.gserviceaccount.com"
    endswith(parts[0], "-compute")
    n := trim_suffix(parts[0], "-compute")
    regex.match(`^[0-9]+$`, n)
}

tocm_sa_project_number(sa) := n {
    parts := split(tocm_sa_email(sa), "@")
    count(parts) == 2
    {"cloudservices.gserviceaccount.com", "cloudbuild.gserviceaccount.com"}[parts[1]]
    n := parts[0]
    regex.match(`^[0-9]+$`, n)
}

# A service account: listed exactly, or its project ID or number is allowed.
tocm_sa_allowed(sa, allowed_sas, _, _) {
    tocm_sa_email(sa) == tocm_sa_email(allowed_sas[_])
}

tocm_sa_allowed(sa, _, allowed_project_ids, _) {
    tocm_sa_project_id(sa) == lower(trim_space(allowed_project_ids[_]))
}

tocm_sa_allowed(sa, _, _, allowed_project_numbers) {
    tocm_sa_project_number(sa) == sprintf("%v", [allowed_project_numbers[_]])
}

# An IAM member string ("user:a@corp.com", "serviceAccount:...", "domain:corp.com").
# cfg keys, all optional lists: members (exact member strings, for principal://,
# special groups and anything else), emails, domains, service_accounts,
# project_ids, project_numbers. allUsers and allAuthenticatedUsers pass only
# when listed in members.
tocm_member_type(m) := t {
    is_string(m)
    i := indexof(m, ":")
    i > 0
    t := substring(m, 0, i)
}

tocm_member_value(m) := v {
    is_string(m)
    i := indexof(m, ":")
    i > 0
    v := substring(m, i + 1, -1)
}

tocm_member_allowed(m, cfg) {
    trim_space(m) == trim_space(object.get(cfg, "members", [])[_])
}

tocm_member_allowed(m, cfg) {
    {"user", "group"}[tocm_member_type(m)]
    tocm_email_allowed(tocm_member_value(m), object.get(cfg, "emails", []), object.get(cfg, "domains", []))
}

tocm_member_allowed(m, cfg) {
    tocm_member_type(m) == "serviceAccount"
    tocm_sa_allowed(tocm_member_value(m), object.get(cfg, "service_accounts", []), object.get(cfg, "project_ids", []), object.get(cfg, "project_numbers", []))
}

tocm_member_allowed(m, cfg) {
    tocm_member_type(m) == "domain"
    tocm_domain_allowed(tocm_member_value(m), object.get(cfg, "domains", []))
}
# --- toc-match end: email v1 ---

# --- toc-match begin: bqaccess v1 ---
# A BigQuery dataset access entry as an IAM member string. BigQuery files
# service accounts under userByEmail, so those become serviceAccount members.
# Wiz sends every member field, unused ones as "", so only a non-empty field
# names the member. Entries for views, routines and datasets have no member.
tocm_bq_access_member(entry) := m {
    v := entry.userByEmail
    is_string(v)
    v != ""
    not tocm_bq_is_sa_email(v)
    m := sprintf("user:%s", [v])
}

tocm_bq_access_member(entry) := m {
    v := entry.userByEmail
    is_string(v)
    v != ""
    tocm_bq_is_sa_email(v)
    m := sprintf("serviceAccount:%s", [v])
}

tocm_bq_access_member(entry) := m {
    v := entry.groupByEmail
    is_string(v)
    v != ""
    m := sprintf("group:%s", [v])
}

tocm_bq_access_member(entry) := m {
    v := entry.domain
    is_string(v)
    v != ""
    m := sprintf("domain:%s", [v])
}

tocm_bq_access_member(entry) := m {
    v := entry.iamMember
    is_string(v)
    v != ""
    m := v
}

tocm_bq_access_member(entry) := m {
    v := entry.specialGroup
    is_string(v)
    v != ""
    m := sprintf("specialGroup:%s", [v])
}

tocm_bq_is_sa_email(v) {
    parts := split(lower(trim_space(v)), "@")
    count(parts) == 2
    parts[1] == "gserviceaccount.com"
}

tocm_bq_is_sa_email(v) {
    parts := split(lower(trim_space(v)), "@")
    count(parts) == 2
    endswith(parts[1], ".gserviceaccount.com")
}
# --- toc-match end: bqaccess v1 ---

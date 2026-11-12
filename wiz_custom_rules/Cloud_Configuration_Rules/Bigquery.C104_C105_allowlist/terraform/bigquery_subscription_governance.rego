package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# 1. Who may hold a role that can subscribe.
#    domains: users and groups. "yourcompany.com" matches only that domain;
#      add "*.yourcompany.com" to approve its subdomains.
#    emails: single users or groups, by exact address.
#    service_accounts: single service accounts, by exact address.
#    project_ids: every service account created in these projects.
#    project_numbers: the default Compute Engine and Google APIs accounts of
#      these projects.
#    members: exact members of any other kind.
#    A domain never approves a service account. allUsers,
#    allAuthenticatedUsers and a grant to a whole domain ("domain:...") are
#    always reported.
authorized_subscribers := {
    "domains": ["yourcompany.com", "partner-domain.com"],
    "emails": [],
    "service_accounts": [],
    "project_ids": ["my-project"],
    "project_numbers": [],
    "members": []
}

# 2. Roles that grant subscription capability.
subscriber_roles := {
    "roles/analyticshub.subscriber",
    "roles/analyticshub.admin"
}

# --- Helpers ---
blocked_public_principals := {"allUsers", "allAuthenticatedUsers"}

# A member set from a variable or another resource is not known until
# apply, so it is never approved.
member_authorized(m) {
    not blocked_public_principals[m]
    tocm_member_type(m) != "domain"
    tocm_member_allowed(m, authorized_subscribers)
}

# A role set from a variable or another resource may be a subscriber role,
# so its members are checked.
role_in_scope(role) {
    subscriber_roles[role]
}

role_in_scope(role) {
    tocm_tf_unresolved(role)
}

iam_member_types := {
    "google_bigquery_analytics_hub_data_exchange_iam_member",
    "google_bigquery_analytics_hub_listing_iam_member"
}

iam_binding_types := {
    "google_bigquery_analytics_hub_data_exchange_iam_binding",
    "google_bigquery_analytics_hub_listing_iam_binding"
}

iam_policy_types := {
    "google_bigquery_analytics_hub_data_exchange_iam_policy",
    "google_bigquery_analytics_hub_listing_iam_policy"
}

# The policy form takes its bindings from a google_iam_policy data source,
# which policy_data names.
policy_source_name(res) := source {
    ref := sprintf("%v", [object.get(res, "policy_data", "")])
    found := regex.find_all_string_submatch_n(`^\$\{\s*data\.google_iam_policy\.([A-Za-z0-9_-]+)\.policy_data\s*\}$`, ref, 1)
    count(found) == 1
    source := found[0][1]
}

# The data source is read from the file that declares the policy: a data
# source with the same name in another module is a different policy. Bindings
# built with a dynamic block are not in the source as text, so such a policy
# cannot be read.
policy_source(document, res) := source {
    source := document.data.google_iam_policy[policy_source_name(res)]
    not source.dynamic
}

policy_is_readable(document, res) {
    policy_source(document, res)
}

# Every subscriber-role grant, in the three forms the provider offers on
# exchanges and listings.
subscriber_grants[grant] {
    document := input.document[i]
    rtype := iam_member_types[_]
    res := document.resource[rtype][name]
    role_in_scope(object.get(res, "role", ""))
    grant := {"documentId": document.id, "resourceType": rtype,
              "name": name, "res": res, "member": object.get(res, "member", ""),
              "searchKey": sprintf("%s[%s].member", [rtype, name])}
}

subscriber_grants[grant] {
    document := input.document[i]
    rtype := iam_binding_types[_]
    res := document.resource[rtype][name]
    role_in_scope(object.get(res, "role", ""))
    member := terraLib.getArray(object.get(res, "members", []))[midx]
    grant := {"documentId": document.id, "resourceType": rtype,
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("%s[%s].members[%d]", [rtype, name, midx])}
}

subscriber_grants[grant] {
    document := input.document[i]
    rtype := iam_policy_types[_]
    res := document.resource[rtype][name]
    binding := terraLib.getArray(policy_source(document, res).binding)[_]
    role_in_scope(object.get(binding, "role", ""))
    member := terraLib.getArray(object.get(binding, "members", []))[_]
    grant := {"documentId": document.id, "resourceType": rtype,
              "name": name, "res": res, "member": member,
              "searchKey": sprintf("%s[%s].policy_data", [rtype, name])}
}

# --- Logic ---
# Finding: subscriber-capable role granted to an identity that is not approved.
WizPolicy[result] {
    grant := subscriber_grants[_]
    not member_authorized(grant.member)

    result := {
        "documentId": grant.documentId,
        "resourceType": grant.resourceType,
        "resourceName": terraLib.get_resource_name(grant.res, grant.name),
        "searchKey": grant.searchKey,
        "issueType": "IncorrectValue",
        "keyExpectedValue": "a role that can subscribe may be granted only to members approved in authorized_subscribers: a user or group by domain or exact email, a service account by exact email or approved project; never allUsers, allAuthenticatedUsers or a whole domain. The rule reads IAM grants only: subscriptions that already exist are not checked",
        "keyActualValue": sprintf("'%v' holds a role that can subscribe and is not approved", [grant.member]),
        "resourceTags": object.get(grant.res, "labels", {}),
    }
}

# Finding: an IAM policy whose bindings the source does not show.
WizPolicy[result] {
    document := input.document[i]
    rtype := iam_policy_types[_]
    res := document.resource[rtype][name]
    not policy_is_readable(document, res)

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("%s[%s].policy_data", [rtype, name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "policy_data must name a google_iam_policy data source in the same file, with its binding blocks written out (no dynamic block), so its members can be checked",
        "keyActualValue": "the members this policy grants cannot be read from the source",
        "resourceTags": object.get(res, "labels", {}),
    }
}

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

# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

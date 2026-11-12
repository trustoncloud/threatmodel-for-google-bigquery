package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher.
# Who may hold access on a dataset.
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

blocked_public_members := {"allUsers", "allAuthenticatedUsers"}

# Mandatory access entity: this group must own every dataset, through an
# inline access block, a google_bigquery_dataset_access resource or a
# google_bigquery_dataset_iam_member, _binding or _policy resource.
required_group := "data-admins@yourcompany.com"

# The two names BigQuery uses for the owner role: the first in access
# entries, the second in IAM grants.
required_roles := {"OWNER", "roles/bigquery.dataOwner"}

# --- Helpers ---
# An access entry (inline block or google_bigquery_dataset_access) as an IAM
# member string. Entries for views, routines and datasets carry no member.
access_member(entry) := tocm_bq_access_member({
    "userByEmail": object.get(entry, "user_by_email", ""),
    "groupByEmail": object.get(entry, "group_by_email", ""),
    "domain": object.get(entry, "domain", ""),
    "iamMember": object.get(entry, "iam_member", ""),
    "specialGroup": object.get(entry, "special_group", ""),
})

# Every member granted on a dataset in the scan, whichever resource grants it.
grants[g] {
    document := input.document[doc]
    ds := document.resource.google_bigquery_dataset[name]
    entry := terraLib.getArray(ds.access)[idx]
    g := {
        "document": document.id,
        "doc": doc,
        "type": "google_bigquery_dataset",
        "name": name,
        "key": sprintf("google_bigquery_dataset[%s].access[%d]", [name, idx]),
        "member": access_member(entry),
        "role": object.get(entry, "role", ""),
        "resource": ds,
        "conditional": is_conditional(entry),
        "inline": true,
    }
}

grants[g] {
    document := input.document[doc]
    res := document.resource.google_bigquery_dataset_access[name]
    g := {
        "document": document.id,
        "doc": doc,
        "type": "google_bigquery_dataset_access",
        "name": name,
        "key": sprintf("google_bigquery_dataset_access[%s]", [name]),
        "member": access_member(res),
        "role": object.get(res, "role", ""),
        "resource": res,
        "conditional": is_conditional(res),
        "inline": false,
    }
}

grants[g] {
    document := input.document[doc]
    res := document.resource.google_bigquery_dataset_iam_member[name]
    g := {
        "document": document.id,
        "doc": doc,
        "type": "google_bigquery_dataset_iam_member",
        "name": name,
        "key": sprintf("google_bigquery_dataset_iam_member[%s].member", [name]),
        "member": res.member,
        "role": object.get(res, "role", ""),
        "resource": res,
        "conditional": is_conditional(res),
        "inline": false,
    }
}

grants[g] {
    document := input.document[doc]
    res := document.resource.google_bigquery_dataset_iam_binding[name]
    member := terraLib.getArray(res.members)[idx]
    g := {
        "document": document.id,
        "doc": doc,
        "type": "google_bigquery_dataset_iam_binding",
        "name": name,
        "key": sprintf("google_bigquery_dataset_iam_binding[%s].members[%d]", [name, idx]),
        "member": member,
        "role": object.get(res, "role", ""),
        "resource": res,
        "conditional": is_conditional(res),
        "inline": false,
    }
}

# A google_bigquery_dataset_iam_policy takes its bindings from a
# google_iam_policy data source, which policy_data names.
grants[g] {
    document := input.document[doc]
    res := document.resource.google_bigquery_dataset_iam_policy[name]
    binding := policy_bindings(document, res)[_]
    member := terraLib.getArray(binding.members)[_]
    g := {
        "document": document.id,
        "doc": doc,
        "type": "google_bigquery_dataset_iam_policy",
        "name": name,
        "key": sprintf("google_bigquery_dataset_iam_policy[%s].policy_data", [name]),
        "member": member,
        "role": object.get(binding, "role", ""),
        "resource": res,
        "conditional": is_conditional(binding),
        "inline": false,
    }
}

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

policy_bindings(document, res) := [binding |
    binding := terraLib.getArray(policy_source(document, res).binding)[_]
]

policy_is_readable(document, res) {
    policy_source(document, res)
}

# A grant with a condition holds only while the condition does. A dynamic
# block inside the grant can build a condition the source does not show, so it
# counts as one.
is_conditional(grant) := true {
    grant.condition
} else := true {
    grant.dynamic
} else := false

member_is_public(member) {
    blocked_public_members[member]
}

member_is_public(member) {
    blocked_public_members[trim_prefix(member, "specialGroup:")]
}

# A conditional grant does not give the group standing access, so it does
# not count as the mandatory admin.
is_required_admin(g) {
    not g.conditional
    required_roles[g.role]
    lower(g.member) == lower(sprintf("group:%s", [required_group]))
}

# A grant belongs to a dataset when it sits inline on it, or when the two
# share a module, its dataset_id is that dataset's ID or a reference to that
# dataset resource, and both name the same project (or both leave the project
# to the same provider configuration).
grant_targets(g, ds, dsname, ds_doc) {
    g.inline
    g.name == dsname
    g.doc == ds_doc
}

grant_targets(g, ds, dsname, ds_doc) {
    not g.inline
    same_module(g.resource, g.doc, ds_doc, dsname)
    same_dataset_id(g.resource, ds, dsname)
    same_project(g.resource, ds, dsname)
}

# Nothing shows the two share a module, so both must write the same dataset
# ID and the same project.
grant_targets(g, ds, dsname, ds_doc) {
    not g.inline
    is_literal(g.resource.dataset_id)
    g.resource.dataset_id == ds.dataset_id
    is_literal(g.resource.project)
    g.resource.project == ds.project
}

# Two resources are known to share a module, and with it a default project,
# when they sit in the same file, or when one points at the dataset by a
# resource name that only one dataset in the scan has. A scan can hold files
# from several modules, so the same ID in another file proves nothing.
same_module(res, res_doc, ds_doc, dsname) {
    res_doc == ds_doc
}

same_module(res, res_doc, ds_doc, dsname) {
    res.dataset_id == sprintf("${google_bigquery_dataset.%s.dataset_id}", [dsname])
    count({d | input.document[d].resource.google_bigquery_dataset[dsname]}) == 1
}

# A value written in the resource. A value taken from a variable or another
# resource is not known until apply.
is_literal(v) {
    is_string(v)
    v != ""
    not tocm_tf_unresolved(v)
}

same_dataset_id(res, ds, dsname) {
    res.dataset_id == sprintf("${google_bigquery_dataset.%s.dataset_id}", [dsname])
}

same_dataset_id(res, ds, dsname) {
    res.dataset_id == ds.dataset_id
}

# Neither sets a project, so each takes the default project of its provider
# configuration. That is the same project only when both use the same
# provider configuration.
same_project(res, ds, dsname) {
    object.get(res, "project", "") == ""
    object.get(ds, "project", "") == ""
    provider_configuration(res) == provider_configuration(ds)
}

# The provider configuration a resource uses. Leaving provider out and
# writing provider = google both select the default configuration.
provider_configuration(resource) := "google" {
    default_provider_values[object.get(resource, "provider", "")]
} else := object.get(resource, "provider", "")

default_provider_values := {"", "google", "${google}"}

same_project(res, ds, dsname) {
    res.project == ds.project
}

same_project(res, ds, dsname) {
    res.project == sprintf("${google_bigquery_dataset.%s.project}", [dsname])
}

has_required_admin(ds, dsname, ds_doc) {
    g := grants[_]
    is_required_admin(g)
    grant_targets(g, ds, dsname, ds_doc)
}

# A dynamic block sits under a "dynamic" key, as a list of blocks or as one
# object keyed by the block name.
has_dynamic_access(ds) {
    ds.dynamic[_].access
}

has_dynamic_access(ds) {
    ds.dynamic.access
}

# --- Logic ---
# Finding: public access, granted inline or through any grant resource.
WizPolicy[result] {
    g := grants[_]
    member_is_public(g.member)

    result := {
        "documentId": g.document,
        "resourceType": g.type,
        "resourceName": terraLib.get_resource_name(g.resource, g.name),
        "searchKey": g.key,
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("access must not include public members: %v", [blocked_public_members]),
        "keyActualValue": sprintf("'%v' grants public access", [g.member]),
        "resourceTags": object.get(g.resource, "labels", {}),
    }
}

# Finding: a member that is not approved, granted inline or through any
# grant resource. A member set from a variable or another resource is not
# known until apply, so it is never approved.
WizPolicy[result] {
    g := grants[_]
    not member_is_public(g.member)
    not tocm_member_allowed(g.member, authorized_access)

    result := {
        "documentId": g.document,
        "resourceType": g.type,
        "resourceName": terraLib.get_resource_name(g.resource, g.name),
        "searchKey": g.key,
        "issueType": "IncorrectValue",
        "keyExpectedValue": "access members must be approved in authorized_access: a user, group or domain by domain or exact email, a service account by exact email or approved project",
        "keyActualValue": sprintf("'%v' is not an approved member", [g.member]),
        "resourceTags": object.get(g.resource, "labels", {}),
    }
}

# Finding: a dataset IAM policy whose bindings the source does not show.
WizPolicy[result] {
    document := input.document[i]
    res := document.resource.google_bigquery_dataset_iam_policy[name]
    not policy_is_readable(document, res)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset_iam_policy",
        "resourceName": terraLib.get_resource_name(res, name),
        "searchKey": sprintf("google_bigquery_dataset_iam_policy[%s].policy_data", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "policy_data must name a google_iam_policy data source in the same file, with its binding blocks written out (no dynamic block), so its members can be checked",
        "keyActualValue": "the members this policy grants cannot be read from the source",
        "resourceTags": object.get(res, "labels", {}),
    }
}

# Finding: a dataset whose access entries are built with a dynamic block,
# which are not in the source as text.
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    has_dynamic_access(ds)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].dynamic.access", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "access blocks must be written out (no dynamic block), so each member can be checked",
        "keyActualValue": "the members a dynamic access block grants cannot be read from the source",
        "resourceTags": object.get(ds, "labels", {}),
    }
}

# Finding: dataset without the mandatory admin group (drift detection).
WizPolicy[result] {
    document := input.document[i]
    ds := document.resource.google_bigquery_dataset[name]
    not has_required_admin(ds, name, i)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_dataset",
        "resourceName": terraLib.get_resource_name(ds, name),
        "searchKey": sprintf("google_bigquery_dataset[%s].access", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": sprintf("'group:%v' must hold the owner role on this dataset (in this project) with no condition, inline or through a dataset access or dataset IAM resource", [required_group]),
        "keyActualValue": "mandatory admin group is not granted on this dataset",
        "resourceTags": object.get(ds, "labels", {}),
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

# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

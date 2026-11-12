package wiz

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

# 2. Projects that may hold a subscription to a whole data exchange (a data
#    clean room), by project ID. Such a subscription names a contact the
#    subscriber writes, so it is approved by the project that holds it.
authorized_exchange_subscriber_project_ids := {
    "my-project"
}

# --- Logic ---
default result := "pass"

# A subscription name is projects/<project>/locations/<location>/subscriptions/<id>.
is_subscription {
    regex.match(`^projects/[^/]+/locations/[^/]+/subscriptions/[^/]+$`, object.get(input, "name", ""))
}

# state is an integer: 1 active, 2 stale, 3 inactive. An inactive subscription
# was cancelled or revoked and gives no access to the data, so it is not
# judged. A stale one still gives access.
is_inactive {
    input.state == 3
}

# The subscriber's email address. A request to subscribe to a listing cannot
# set it, so on a listing subscription it names the account that subscribed.
# A request to subscribe to a whole exchange can set it, so there it is only
# what the subscriber wrote, and the project that holds the subscription
# decides instead.
subscriber := trim_space(sprintf("%v", [object.get(input, "subscriber_contact", "")]))

listing_subscription {
    is_string(input.ResourceName.Listing)
    input.ResourceName.Listing != ""
}

exchange_subscription {
    not listing_subscription
    is_string(input.ResourceName.DataExchange)
    input.ResourceName.DataExchange != ""
}

# The subscription's name carries the project ID of the project that holds it.
subscription_project := split(input.name, "/")[1]

subscriber_approved {
    tocm_email_allowed(subscriber, authorized_subscribers.emails, authorized_subscribers.domains)
}

subscriber_approved {
    tocm_sa_allowed(subscriber, authorized_subscribers.service_accounts, authorized_subscribers.project_ids, authorized_subscribers.project_numbers)
}

# What the subscription is to: one listing, or a whole data exchange.
subscribed_resource := r {
    r := input.ResourceName.Listing
    is_string(r)
} else := r {
    r := input.ResourceName.DataExchange
    is_string(r)
} else := "an unnamed listing or exchange"

issues[msg] {
    listing_subscription
    subscriber == ""
    msg := sprintf("the subscription to '%v' names no subscriber", [subscribed_resource])
}

issues[msg] {
    listing_subscription
    subscriber != ""
    not subscriber_approved
    msg := sprintf("'%v' holds a subscription to '%v' and is not an approved subscriber", [subscriber, subscribed_resource])
}

issues[msg] {
    exchange_subscription
    not authorized_exchange_subscriber_project_ids[subscription_project]
    msg := sprintf("project '%v' holds a subscription to the whole exchange '%v' and is not approved to subscribe to whole exchanges", [subscription_project, subscribed_resource])
}

issues[msg] {
    not listing_subscription
    not exchange_subscription
    msg := "the subscription names no listing or exchange, so its subscriber cannot be judged"
}

# --- Aggregation ---
result := "skip" {
    not is_subscription
} else := "skip" {
    is_inactive
} else := "fail" {
    count(issues) > 0
}

# --- Metadata ---
currentConfiguration := sprintf("Unauthorized subscription: %v", [concat("; ", sort(issues))]) {
    result == "fail"
} else := "The subscription was cancelled or revoked and gives no access" {
    is_subscription
    is_inactive
} else := "The subscription to a whole exchange is held in an approved project" {
    exchange_subscription
} else := "The subscription is held by an approved subscriber"

expectedConfiguration := "Every active or stale subscription to a listing or data exchange must be held by a subscriber approved in authorized_subscribers (a domain, an email address, a service account or a project). A subscription to a whole exchange must instead sit in a project listed in authorized_exchange_subscriber_project_ids, because its subscriber contact is supplied by the subscriber. Only subscriptions in projects that are scanned can be read."

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

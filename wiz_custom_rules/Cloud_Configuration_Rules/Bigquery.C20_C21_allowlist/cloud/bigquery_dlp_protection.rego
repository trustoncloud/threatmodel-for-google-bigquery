package wiz

# --- Configuration ---
# Inspect templates approved for BigQuery scans, by full name. A template
# created without a location is in global, so the two forms
# "projects/p/inspectTemplates/t" and
# "projects/p/locations/global/inspectTemplates/t" name the same template and
# either may be listed. A trigger names its template the way it was written,
# by project ID or project number, so list it the same way.
authorized_templates := {
    "projects/my-project/inspectTemplates/strict-pii-v1",
    "projects/my-project/inspectTemplates/finance-pci-v1"
}

# --- Logic ---
default result := "pass"

# The rule reads the scan's inspection rules and status only. It does not
# show that data was redacted, or that every sensitive table has a trigger.

inspect_job := input.Job.InspectJob

# storage_config.Type holds one of BigQueryOptions, CloudStorageOptions,
# DatastoreOptions or HybridOptions.
targets_bigquery {
    is_object(inspect_job.storage_config.Type.BigQueryOptions)
}

# An unset template arrives as "".
template := object.get(inspect_job, "inspect_template_name", "")

# A template name with the global location written out, so both forms of a
# global template compare equal. Any other name is returned unchanged.
global_form(name) := sprintf("%s/%s/locations/global/inspectTemplates/%s", [s[0], s[1], s[3]]) {
    s := split(tocm_gcp_rel(name), "/")
    count(s) == 4
    s[2] == "inspectTemplates"
} else := name

authorized_global_forms := {global_form(t) | t := authorized_templates[_]}

fail_template {
    not tocm_gcp_name_allowed(global_form(template), authorized_global_forms)
}

# DLP merges inspect_config into the template, so an inline config can lower
# the likelihood, change the info types or add exclusion rules. The field is
# absent when unset.
fail_inline_config {
    is_object(inspect_job.inspect_config)
}

# status is the enum as an integer: 1 HEALTHY, 2 PAUSED, 3 CANCELLED. An
# unspecified status (0) arrives as no field. Only a HEALTHY trigger runs.
status := object.get(input, "status", 0)

status_names := {0: "STATUS_UNSPECIFIED", 1: "HEALTHY", 2: "PAUSED", 3: "CANCELLED"}

status_label := object.get(status_names, status, sprintf("%v", [status]))

is_healthy {
    status == 1
}

is_healthy {
    status == "HEALTHY"
}

fail_status {
    not is_healthy
}

# --- Aggregation ---
result := "skip" {
    not is_object(inspect_job)
} else := "skip" {
    not targets_bigquery
} else := "fail" {
    fail_template
} else := "fail" {
    fail_inline_config
} else := "fail" {
    fail_status
}

# --- Metadata ---
issues[msg] {
    fail_template
    template == ""
    msg := "no inspect template is set"
}

issues[msg] {
    fail_template
    template != ""
    msg := sprintf("inspect template '%v' is not authorized", [template])
}

issues[msg] {
    fail_inline_config
    msg := "an inline inspect_config is merged into the template"
}

issues[msg] {
    fail_status
    msg := sprintf("status is %v, so the trigger does not scan", [status_label])
}

currentConfiguration := sprintf("Issues found: %v", [concat("; ", sort([m | m := issues[_]]))]) {
    result == "fail"
} else := sprintf("The trigger is HEALTHY and uses the authorized template '%v' with no inline inspect_config.", [template])

expectedConfiguration := sprintf("DLP triggers that scan BigQuery must be HEALTHY and take their inspection rules only from an authorized template, with no inline inspect_config: %v. This checks the scan's inspection rules and status only, not that data was redacted or that every sensitive table is scanned.", [authorized_templates])

# --- Matching helpers ---
# --- toc-match begin: gcpname v1 ---
# Relative GCP resource name ("projects/p/locations/l/dataExchanges/x") from
# a relative name, a full name ("//bigquery.googleapis.com/projects/...") or a
# self link ("https://www.googleapis.com/compute/v1/projects/..."). Names
# compare segment by segment, so Compute's global resources
# ("projects/p/global/networks/n"), image families
# (".../global/images/family/f") and uid paths keep their own shape.
tocm_gcp_rel(name) := r {
    is_string(name)
    n := trim_space(name)
    not contains(n, "//")
    r := trim_suffix(n, "/")
}

tocm_gcp_rel(name) := r {
    is_string(name)
    n := trim_space(name)
    contains(n, "//")
    starts := [i |
        root := ["/projects/", "/organizations/", "/folders/", "/billingAccounts/"][_]
        i := indexof(n, root)
        i >= 0
    ]
    count(starts) > 0
    r := trim_suffix(substring(n, min(starts) + 1, -1), "/")
}

# Segments in order; the id after locations, regions or zones is lowercased
# because surfaces disagree on its case.
tocm_gcp_name_norm(name) := [x |
    s := split(tocm_gcp_rel(name), "/")
    some i
    s[i]
    x := tocm_gcp_seg(s, i)
]

tocm_gcp_seg(s, i) := lower(s[i]) {
    i > 0
    {"locations", "regions", "zones"}[s[i - 1]]
}

tocm_gcp_seg(s, i) := s[i] {
    i == 0
}

tocm_gcp_seg(s, i) := s[i] {
    i > 0
    not {"locations", "regions", "zones"}[s[i - 1]]
}

tocm_gcp_name_ok(name) {
    s := split(tocm_gcp_rel(name), "/")
    count(s) >= 2
    {"projects", "organizations", "folders", "billingAccounts"}[s[0]]
    not tocm_gcp_has_empty(s)
}

tocm_gcp_has_empty(s) {
    s[_] == ""
}

# Two names identify the same resource. A project ID never matches a project
# number: configure each surface the way it reports names (Analytics Hub
# cloud payloads carry the project number).
tocm_gcp_name_equal(a, b) {
    tocm_gcp_name_ok(a)
    tocm_gcp_name_ok(b)
    tocm_gcp_name_norm(a) == tocm_gcp_name_norm(b)
}

tocm_gcp_name_allowed(name, allowed) {
    tocm_gcp_name_equal(name, allowed[_])
}

# Relative name from Terraform arguments, for comparing with cloud names.
tocm_gcp_name(project, location, collection, id) := sprintf("projects/%s/locations/%s/%s/%s", [project, lower(location), collection, id])
# --- toc-match end: gcpname v1 ---

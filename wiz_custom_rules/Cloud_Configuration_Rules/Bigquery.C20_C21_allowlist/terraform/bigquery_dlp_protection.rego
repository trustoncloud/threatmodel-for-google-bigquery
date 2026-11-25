package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Inspect templates approved for BigQuery scans, by full name. A template
# created without a location is in global, so the two forms
# "projects/p/inspectTemplates/t" and
# "projects/p/locations/global/inspectTemplates/t" name the same template and
# either may be listed.
authorized_templates := {
    "projects/my-project/inspectTemplates/strict-pii-v1",
    "projects/my-project/inspectTemplates/finance-pci-v1"
}

# --- Helpers ---
# The rule reads the scan's inspection rules and status only. It does not
# show that data was redacted, or that every sensitive table has a trigger.

scans_bigquery(ij) {
    sc := tocm_tf_blocks(ij, "storage_config")[_]
    count(tocm_tf_blocks(sc, "big_query_options")) > 0
}

# The trigger's inspect jobs that scan BigQuery.
bigquery_jobs(trigger) := {ij |
    ij := tocm_tf_blocks(trigger, "inspect_job")[_]
    scans_bigquery(ij)
}

# A template name with the global location written out, so both forms of a
# global template compare equal. Any other name is returned unchanged.
global_form(name) := sprintf("%s/%s/locations/global/inspectTemplates/%s", [s[0], s[1], s[3]]) {
    s := split(tocm_gcp_rel(name), "/")
    count(s) == 4
    s[2] == "inspectTemplates"
} else := name

authorized_global_forms := {global_form(t) | t := authorized_templates[_]}

template_authorized(template) {
    not tocm_tf_unresolved(template)
    tocm_gcp_name_allowed(global_form(template), authorized_global_forms)
}

# A template set from a variable or another resource is not known until
# apply, so it is never approved.
template_problem(template) := sprintf("inspect_template_name is '%v', which is not known until apply", [template]) {
    tocm_tf_unresolved(template)
} else := sprintf("inspect_template_name is '%v'", [template])

# DLP merges an inline inspect_config into the template, so an inline config
# can lower the likelihood, change the info types or add exclusion rules.
has_inline_config(ij) {
    count(tocm_tf_blocks(ij, "inspect_config")) > 0
}

# An unset or empty status takes the provider default, HEALTHY. A PAUSED or
# CANCELLED trigger never scans.
status_problem(trigger) := sprintf("status is '%v', which is not known until apply", [trigger.status]) {
    tocm_tf_unresolved(trigger.status)
} else := sprintf("status is '%v', so the trigger does not scan", [trigger.status]) {
    is_string(trigger.status)
    not {"", "HEALTHY"}[trigger.status]
}

# --- Logic ---
# Finding: BigQuery DLP trigger without an authorized managed template.
WizPolicy[result] {
    document := input.document[i]
    trigger := document.resource.google_data_loss_prevention_job_trigger[name]
    ij := bigquery_jobs(trigger)[_]
    template := object.get(ij, "inspect_template_name", "")
    not template_authorized(template)

    result := {
        "documentId": document.id,
        "resourceType": "google_data_loss_prevention_job_trigger",
        "resourceName": terraLib.get_resource_name(trigger, name),
        "searchKey": sprintf("google_data_loss_prevention_job_trigger[%s].inspect_job.inspect_template_name", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("BigQuery DLP triggers must use an authorized template: %v (this checks the scan's inspection rules only, not that data was redacted or that every sensitive table is scanned)", [authorized_templates]),
        "keyActualValue": template_problem(template),
        "resourceTags": object.get(trigger, "labels", {}),
    }
}

# Finding: BigQuery DLP trigger that overrides its template with an inline
# inspect_config.
WizPolicy[result] {
    document := input.document[i]
    trigger := document.resource.google_data_loss_prevention_job_trigger[name]
    ij := bigquery_jobs(trigger)[_]
    has_inline_config(ij)

    result := {
        "documentId": document.id,
        "resourceType": "google_data_loss_prevention_job_trigger",
        "resourceName": terraLib.get_resource_name(trigger, name),
        "searchKey": sprintf("google_data_loss_prevention_job_trigger[%s].inspect_job.inspect_config", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "BigQuery DLP triggers must take their inspection rules from an authorized template only, with no inline inspect_config",
        "keyActualValue": "inspect_job sets an inline inspect_config, which DLP merges into the template",
        "resourceTags": object.get(trigger, "labels", {}),
    }
}

# Finding: BigQuery DLP trigger that is paused or cancelled.
WizPolicy[result] {
    document := input.document[i]
    trigger := document.resource.google_data_loss_prevention_job_trigger[name]
    count(bigquery_jobs(trigger)) > 0
    problem := status_problem(trigger)

    result := {
        "documentId": document.id,
        "resourceType": "google_data_loss_prevention_job_trigger",
        "resourceName": terraLib.get_resource_name(trigger, name),
        "searchKey": sprintf("google_data_loss_prevention_job_trigger[%s].status", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "BigQuery DLP triggers must be HEALTHY (or leave status unset) so they run",
        "keyActualValue": problem,
        "resourceTags": object.get(trigger, "labels", {}),
    }
}

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

# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

# --- toc-match begin: tfblock v1 ---
# Blocks of a Terraform resource, written out or built by a dynamic block. A
# dynamic block sits under a "dynamic" key, as a list of blocks or as one
# block, with its body under "content". Its for_each decides how many blocks
# it builds. A literal list or map, or toset, tolist or tomap of one, has a
# known size; anything else (a variable without a default, a for expression,
# another resource) is unknown.
tocm_tf_list(v) := v {
    is_array(v)
} else := [v]

tocm_tf_dynamic(obj, name) := {d | d := obj.dynamic[_][name]} | {d | d := obj.dynamic[name]}

# The expression inside "${...}", or the value itself.
tocm_tf_expr(v) := substring(t, 2, count(t) - 3) {
    t := trim_space(v)
    startswith(t, "${")
    endswith(t, "}")
} else := trim_space(v)

tocm_tf_known_empty(v) {
    is_array(v)
    count(v) == 0
}

tocm_tf_known_empty(v) {
    is_object(v)
    count(v) == 0
}

tocm_tf_known_empty(v) {
    is_string(v)
    regex.match(`^(toset|tolist|tomap)\(\s*(\[\s*\]|\{\s*\})\s*\)$`, tocm_tf_expr(v))
}

tocm_tf_known_nonempty(v) {
    is_array(v)
    count(v) > 0
}

tocm_tf_known_nonempty(v) {
    is_object(v)
    count(v) > 0
}

# toset, tolist or tomap of one literal list or map with at least one
# element. Each element counts whatever its value, so [1] and [var.a] have
# one. The whole argument must be that one literal: in
# tolist([1] == [1] ? [] : [1]) the first bracket closes early, so the value
# is unknown. A for expression can build none, so it is unknown too.
tocm_tf_known_nonempty(v) {
    is_string(v)
    m := regex.find_all_string_submatch_n(`(?s)^(?:toset|tolist|tomap)\(\s*(.*?)\s*\)$`, tocm_tf_expr(v), 1)
    arg := tocm_tf_unquoted(m[0][1])
    tocm_tf_one_literal(arg)
    regex.match(`(?s)^[\[{]\s*[^\s\]}]`, arg)
    not regex.match(`^[\[{]\s*for\s`, arg)
}

# The text with every quoted string replaced by s, so a bracket inside a
# string is read as text. A quote left unpaired leaves the text unknown.
tocm_tf_unquoted(arg) := t {
    t := regex.replace(arg, `"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'`, "s")
    not contains(t, "\"")
    not contains(t, "'")
}

# The argument is one bracketed literal: it opens with [ or {, and that
# bracket closes only at the last character.
tocm_tf_one_literal(arg) {
    chars := split(arg, "")
    n := count(chars)
    n >= 2
    {"[", "{"}[chars[0]]
    tocm_tf_depth(chars, n - 1) == 0
    early := [i | chars[i]; i < n - 1; tocm_tf_depth(chars, i) <= 0]
    count(early) == 0
}

# Brackets open minus brackets closed, up to and including position i.
tocm_tf_depth(chars, i) := count([j | chars[j]; j <= i; {"[", "{", "("}[chars[j]]]) - count([j | chars[j]; j <= i; {"]", "}", ")"}[chars[j]]])

# Every block called name inside obj that may exist: written out, or built by
# a dynamic block whose for_each is not known to be empty.
tocm_tf_blocks(obj, name) := found {
    written := {b | b := tocm_tf_list(obj[name])[_]}
    built := {b |
        d := tocm_tf_dynamic(obj, name)[_]
        not tocm_tf_known_empty(d.for_each)
        b := tocm_tf_list(d.content)[_]
    }
    found := written | built
}

# Every block called name inside obj that surely exists: written out, or
# built by a dynamic block whose for_each is known not to be empty.
tocm_tf_sure_blocks(obj, name) := found {
    written := {b | b := tocm_tf_list(obj[name])[_]}
    built := {b |
        d := tocm_tf_dynamic(obj, name)[_]
        tocm_tf_known_nonempty(d.for_each)
        b := tocm_tf_list(d.content)[_]
    }
    found := written | built
}
# --- toc-match end: tfblock v1 ---

package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Constraints that must stay enforced (BigQuery Omni disabled). The matcher
# flags declarations that create Omni connections or weaken the ban; absence
# of an org policy in IaC is not a finding (the ban may be set elsewhere).
omni_constraint_names := {
    "constraints/bigquery.disableBQOmniAWS",
    "constraints/bigquery.disableBQOmniAzure",
    "bigquery.disableBQOmniAWS",
    "bigquery.disableBQOmniAzure"
}

# --- Helpers ---
is_target_constraint(c) {
    omni_constraint_names[c]
}

is_true(v) {
    lower(sprintf("%v", [v])) == "true"
}

# A google_org_policy_policy names its constraint after "/policies/".
is_omni_policy(pol) {
    parts := split(sprintf("%v", [pol.name]), "/policies/")
    count(parts) == 2
    is_target_constraint(parts[1])
}

# A policy names its constraint through a variable or another resource when
# the part of its name after "/policies/" is not a literal value, or the name
# does not show that part at all. Such a constraint is not known until apply,
# so it could be an Omni constraint.
constraint_unknown(pol) {
    parts := split(sprintf("%v", [pol.name]), "/policies/")
    count(parts) == 2
    tocm_tf_unresolved(parts[1])
}

constraint_unknown(pol) {
    policy_name := sprintf("%v", [pol.name])
    tocm_tf_unresolved(policy_name)
    not contains(policy_name, "/policies/")
}

# The Omni constraints are boolean. A policy whose rules all carry list
# settings belongs to a list constraint, so it cannot be one of them.
is_list_policy(pol) {
    spec := terraLib.getValueArrayOrObject(pol.spec)
    rules := terraLib.getArray(spec.rules)
    count(rules) > 0
    count([r | r := rules[_]; list_rule(r)]) == count(rules)
    not is_true(object.get(spec, "reset", false))
}

list_rule(rule) {
    rule.values
}

list_rule(rule) {
    rule.allow_all
}

list_rule(rule) {
    rule.deny_all
}

unknown_constraint_actual(actual) := sprintf("the constraint is set from a value that is not known until apply, and the %s", [replace(actual, "the Omni constraint", "its constraint")])

# Ways the live spec of a google_org_policy_policy stops enforcing its
# constraint everywhere under it. dry_run_spec is not live and is not read.
# reset restores the constraint default, which drops an inherited ban.
spec_weakenings(pol, name) := {w |
    spec := terraLib.getValueArrayOrObject(pol.spec)
    is_true(object.get(spec, "reset", false))
    w := {
        "key": sprintf("google_org_policy_policy[%s].spec.reset", [name]),
        "actual": "policy resets the Omni constraint to its default, which drops an inherited ban",
    }
} | {w |
    spec := terraLib.getValueArrayOrObject(pol.spec)
    rule := terraLib.getArray(spec.rules)[ridx]
    not is_true(object.get(rule, "enforce", false))
    w := {
        "key": sprintf("google_org_policy_policy[%s].spec.rules[%d].enforce", [name, ridx]),
        "actual": "policy declares the Omni constraint unenforced",
    }
} | {w |
    spec := terraLib.getValueArrayOrObject(pol.spec)
    rule := terraLib.getArray(spec.rules)[ridx]
    is_true(object.get(rule, "enforce", false))
    rule.condition
    w := {
        "key": sprintf("google_org_policy_policy[%s].spec.rules[%d].condition", [name, ridx]),
        "actual": "policy enforces the Omni constraint only where a condition holds",
    }
} | {w |
    spec := terraLib.getValueArrayOrObject(pol.spec)
    rule := terraLib.getArray(spec.rules)[ridx]
    is_true(object.get(rule, "enforce", false))
    not rule.condition
    has_dynamic_condition(rule)
    w := {
        "key": sprintf("google_org_policy_policy[%s].spec.rules[%d].condition", [name, ridx]),
        "actual": "policy builds a condition with a dynamic block, so it may enforce the Omni constraint only where that condition holds",
    }
} | {w |
    spec := terraLib.getValueArrayOrObject(pol.spec)
    has_dynamic_rules(spec)
    w := {
        "key": sprintf("google_org_policy_policy[%s].spec.rules", [name]),
        "actual": "policy builds its rules with a dynamic block, so the source does not show that it enforces the Omni constraint",
    }
} | {w |
    spec := terraLib.getValueArrayOrObject(pol.spec)
    not is_true(object.get(spec, "reset", false))
    not spec.rules
    not has_dynamic_rules(spec)
    w := {
        "key": sprintf("google_org_policy_policy[%s].spec", [name]),
        "actual": "policy sets a live spec with no rule that enforces the Omni constraint",
    }
}

# A dynamic block sits under a "dynamic" key, as a list of blocks or as one
# block. What it builds is not in the source as text.
has_dynamic_condition(rule) {
    rule.dynamic[_].condition
}

has_dynamic_condition(rule) {
    rule.dynamic.condition
}

has_dynamic_rules(spec) {
    spec.dynamic[_].rules
}

has_dynamic_rules(spec) {
    spec.dynamic.rules
}

legacy_org_policy_types := {
    "google_organization_policy",
    "google_folder_organization_policy",
    "google_project_organization_policy"
}

# Ways a legacy org policy resource stops enforcing its constraint. An unset
# enforced value is not enforced, and restore_policy restores the constraint
# default, which drops an inherited ban.
legacy_weakenings(rtype, pol, name) := {w |
    bp := terraLib.getValueArrayOrObject(pol.boolean_policy)
    not is_true(object.get(bp, "enforced", false))
    w := {
        "key": sprintf("%s[%s].boolean_policy.enforced", [rtype, name]),
        "actual": "policy declares the Omni constraint unenforced",
    }
} | {w |
    pol.restore_policy
    w := {
        "key": sprintf("%s[%s].restore_policy", [rtype, name]),
        "actual": "policy restores the Omni constraint to its default, which drops an inherited ban",
    }
}

# --- Logic ---
# Finding: any Omni connection declared (the ban means none are allowed).
WizPolicy[result] {
    document := input.document[i]
    conn := document.resource.google_bigquery_connection[name]
    omni_block := {"aws", "azure"}[_]
    conn[omni_block]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_connection",
        "resourceName": terraLib.get_resource_name(conn, name),
        "searchKey": sprintf("google_bigquery_connection[%s].%s", [name, omni_block]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": "BigQuery Omni is disabled by policy; no Omni connections may be declared",
        "keyActualValue": sprintf("connection declares an %v block", [omni_block]),
        "resourceTags": object.get(conn, "labels", {}),
    }
}

# Finding: new-style org policy weakening the Omni ban.
WizPolicy[result] {
    document := input.document[i]
    pol := document.resource.google_org_policy_policy[name]
    is_omni_policy(pol)
    w := spec_weakenings(pol, name)[_]

    result := {
        "documentId": document.id,
        "resourceType": "google_org_policy_policy",
        "resourceName": terraLib.get_resource_name(pol, name),
        "searchKey": w.key,
        "issueType": "IncorrectValue",
        "keyExpectedValue": "the BigQuery Omni disable constraints must stay enforced, with no reset and no condition",
        "keyActualValue": w.actual,
        "resourceTags": object.get(pol, "labels", {}),
    }
}

# Finding: legacy org policy resources weakening the Omni ban.
WizPolicy[result] {
    document := input.document[i]
    rtype := legacy_org_policy_types[_]
    pol := document.resource[rtype][name]
    is_target_constraint(pol.constraint)
    w := legacy_weakenings(rtype, pol, name)[_]

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(pol, name),
        "searchKey": w.key,
        "issueType": "IncorrectValue",
        "keyExpectedValue": "the BigQuery Omni disable constraints must stay enforced, with no restore to the default",
        "keyActualValue": w.actual,
        "resourceTags": object.get(pol, "labels", {}),
    }
}

# Finding: new-style org policy whose constraint is not known until apply
# and whose spec would weaken the ban if the constraint is an Omni one.
WizPolicy[result] {
    document := input.document[i]
    pol := document.resource.google_org_policy_policy[name]
    constraint_unknown(pol)
    not is_list_policy(pol)
    w := spec_weakenings(pol, name)[_]

    result := {
        "documentId": document.id,
        "resourceType": "google_org_policy_policy",
        "resourceName": terraLib.get_resource_name(pol, name),
        "searchKey": w.key,
        "issueType": "IncorrectValue",
        "keyExpectedValue": "a policy that does not enforce its constraint everywhere must write the constraint in the resource, so it can be told apart from the BigQuery Omni disable constraints",
        "keyActualValue": unknown_constraint_actual(w.actual),
        "resourceTags": object.get(pol, "labels", {}),
    }
}

# Finding: legacy org policy resource in the same position.
WizPolicy[result] {
    document := input.document[i]
    rtype := legacy_org_policy_types[_]
    pol := document.resource[rtype][name]
    tocm_tf_unresolved(pol.constraint)
    w := legacy_weakenings(rtype, pol, name)[_]

    result := {
        "documentId": document.id,
        "resourceType": rtype,
        "resourceName": terraLib.get_resource_name(pol, name),
        "searchKey": w.key,
        "issueType": "IncorrectValue",
        "keyExpectedValue": "a policy that does not enforce its constraint everywhere must write the constraint in the resource, so it can be told apart from the BigQuery Omni disable constraints",
        "keyActualValue": unknown_constraint_actual(w.actual),
        "resourceTags": object.get(pol, "labels", {}),
    }
}

# --- Matching helpers ---
# --- toc-match begin: tf v1 ---
# A Terraform value that is still an unresolved reference ("${...}"). Treat
# it as unknown: never compare it with an allowlist as a string.
tocm_tf_unresolved(v) {
    is_string(v)
    contains(v, "${")
}
# --- toc-match end: tf v1 ---

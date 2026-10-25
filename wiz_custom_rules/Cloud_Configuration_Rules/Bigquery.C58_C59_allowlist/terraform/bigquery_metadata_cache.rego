package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Keep in sync with the cloud matcher: staleness between 30 minutes and
# 7 days, cache mode AUTOMATIC or MANUAL.
min_staleness_seconds := 1800

max_staleness_seconds := 604800

authorized_metadata_cache_modes := {"AUTOMATIC", "MANUAL"}

# --- Helpers ---
# max_staleness is a SQL IntervalValue string "Y-M D H:M:S" (e.g. "0-0 0 8:0:0").
interval_seconds(raw) := seconds {
    parts := split(raw, " ")
    count(parts) == 3
    days := to_number(parts[1])
    hms := split(parts[2], ":")
    count(hms) == 3
    seconds := (((days * 24) + to_number(hms[0])) * 3600) + (to_number(hms[1]) * 60) + to_number(hms[2])
}

cache_mode(tbl) := mode {
    cfg := terraLib.getValueArrayOrObject(tbl.external_data_configuration)
    mode := cfg.metadata_cache_mode
}

# --- Logic ---
# Finding: cache mode set to an unsupported value.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    mode := cache_mode(tbl)
    not authorized_metadata_cache_modes[mode]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].external_data_configuration.metadata_cache_mode", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("metadata_cache_mode must be one of: %v", [authorized_metadata_cache_modes]),
        "keyActualValue": sprintf("metadata_cache_mode is '%v'", [mode]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: cache enabled but max_staleness missing or not a valid interval.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    cache_mode(tbl)
    not interval_seconds(object.get(tbl, "max_staleness", ""))

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].max_staleness", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "max_staleness must be a SQL interval (e.g. \"0-0 0 8:0:0\")",
        "keyActualValue": sprintf("max_staleness is '%v'", [object.get(tbl, "max_staleness", "")]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

# Finding: staleness outside the allowed window.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    cache_mode(tbl)
    seconds := interval_seconds(object.get(tbl, "max_staleness", ""))
    outside_window(seconds)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].max_staleness", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("max_staleness must be between %v and %v seconds", [min_staleness_seconds, max_staleness_seconds]),
        "keyActualValue": sprintf("max_staleness is %v seconds", [seconds]),
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

outside_window(seconds) {
    seconds < min_staleness_seconds
}

outside_window(seconds) {
    seconds > max_staleness_seconds
}

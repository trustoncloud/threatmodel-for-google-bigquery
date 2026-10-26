package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal safety baseline: every partitioned table must require a partition
# filter. The flag exists both top-level and (deprecated) inside
# time_partitioning; either satisfies the control.

is_partitioned(tbl) {
    tbl.time_partitioning
}

is_partitioned(tbl) {
    tbl.range_partitioning
}

has_partition_filter(tbl) {
    tbl.require_partition_filter == true
}

has_partition_filter(tbl) {
    tp := terraLib.getValueArrayOrObject(tbl.time_partitioning)
    tp.require_partition_filter == true
}

WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    is_partitioned(tbl)
    not has_partition_filter(tbl)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].require_partition_filter", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "partitioned tables must set require_partition_filter = true",
        "keyActualValue": "table is partitioned but does not require a partition filter",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

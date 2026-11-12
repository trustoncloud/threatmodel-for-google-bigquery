package wiz

import data.generic.terraform as terraLib

# --- Logic ---
# Universal safety baseline: every partitioned table must require a partition
# filter. For time and range partitioning the flag exists both top-level and
# (deprecated) inside time_partitioning; either satisfies the control. A
# Hive-partitioned external table carries its own flag inside
# hive_partitioning_options, and only that flag covers its partitions.

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

hive_options(tbl) := opts {
    edc := terraLib.getValueArrayOrObject(tbl.external_data_configuration)
    opts := terraLib.getValueArrayOrObject(edc.hive_partitioning_options)
}

has_hive_partition_filter(tbl) {
    hive_options(tbl).require_partition_filter == true
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

# Finding: Hive-partitioned external table without its own filter requirement.
WizPolicy[result] {
    document := input.document[i]
    tbl := document.resource.google_bigquery_table[name]
    hive_options(tbl)
    not has_hive_partition_filter(tbl)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_table",
        "resourceName": terraLib.get_resource_name(tbl, name),
        "searchKey": sprintf("google_bigquery_table[%s].external_data_configuration.hive_partitioning_options.require_partition_filter", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "Hive-partitioned external tables must set hive_partitioning_options.require_partition_filter = true",
        "keyActualValue": "table is Hive-partitioned but hive_partitioning_options does not require a partition filter",
        "resourceTags": object.get(tbl, "labels", {}),
    }
}

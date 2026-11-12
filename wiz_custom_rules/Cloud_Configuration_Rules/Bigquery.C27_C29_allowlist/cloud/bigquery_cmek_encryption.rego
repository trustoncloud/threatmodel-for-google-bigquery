package wiz

# --- Configuration ---
# Approved Cloud KMS keys, by full name: project, location, key ring and key
# must all match. List each key without a version. BigQuery names a key,
# never a key version, so an entry ending in /cryptoKeyVersions/<n> matches
# nothing.
authorized_kms_keys := {
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/finance-key",
    "projects/my-secure-project/locations/us/keyRings/my-ring/cryptoKeys/hr-key"
}

# --- Logic ---
default result := "pass"

# The encryption block is absent when the dataset uses Google-managed
# encryption.
key_name := val {
    val := input.defaultEncryptionConfiguration.kmsKeyName
    val != ""
}

is_authorized {
    tocm_kms_allowed(key_name, authorized_kms_keys)
}

# A linked dataset is a read-only view of data another project shares, and
# names the dataset it is linked from in linkedDatasetSource. Its data is
# encrypted where it is stored, so it has no default key to set and is
# skipped.
is_linked_dataset {
    input.linkedDatasetSource
}

# --- Fail Conditions ---
fail_no_cmek {
    not key_name
}

fail_unauthorized_key {
    key_name
    not is_authorized
}

# --- Aggregation ---
result := "skip" {
    not input.datasetReference
} else := "skip" {
    is_linked_dataset
} else := "fail" {
    fail_no_cmek
} else := "fail" {
    fail_unauthorized_key
}

# --- Metadata ---
currentConfiguration := "Linked dataset: read-only, with no default key to set" {
    is_linked_dataset
} else := "Dataset has no default CMEK, so new tables use Google-managed encryption" {
    fail_no_cmek
} else := sprintf("Dataset default key '%v' is not an approved key", [key_name]) {
    fail_unauthorized_key
} else := sprintf("Dataset default key is '%v'", [key_name]) {
    result != "skip"
}

expectedConfiguration := "The dataset's default encryption key must be an approved Cloud KMS key (same project, location, key ring and key). Only the dataset default is checked: a table or model created before the default was set keeps its own key, and the key version in use is chosen in Cloud KMS."

# --- Matching helpers ---
# --- toc-match begin: kms v1 ---
# Parts of a Cloud KMS key name, with or without "//cloudkms.googleapis.com/"
# and with or without "/cryptoKeyVersions/V".
tocm_kms_parts(name) := {"project": s[1], "location": lower(s[3]), "key_ring": s[5], "key": s[7], "version": ""} {
    s := split(tocm_kms_rel(name), "/")
    count(s) == 8
    tocm_kms_shape(s)
}

tocm_kms_parts(name) := {"project": s[1], "location": lower(s[3]), "key_ring": s[5], "key": s[7], "version": s[9]} {
    s := split(tocm_kms_rel(name), "/")
    count(s) == 10
    tocm_kms_shape(s)
    s[8] == "cryptoKeyVersions"
    s[9] != ""
}

tocm_kms_rel(name) := r {
    is_string(name)
    r := trim_prefix(trim_space(name), "//cloudkms.googleapis.com/")
}

tocm_kms_shape(s) {
    s[0] == "projects"
    s[2] == "locations"
    s[4] == "keyRings"
    s[6] == "cryptoKeys"
    s[1] != ""
    s[3] != ""
    s[5] != ""
    s[7] != ""
}

# A key is allowed when project, location, key ring and key all equal an
# entry's. An entry with a version admits that version only; an entry
# without one admits the key at any version.
tocm_kms_allowed(name, allowed) {
    k := tocm_kms_parts(name)
    e := tocm_kms_parts(allowed[_])
    k.project == e.project
    k.location == e.location
    k.key_ring == e.key_ring
    k.key == e.key
    e.version == ""
}

tocm_kms_allowed(name, allowed) {
    k := tocm_kms_parts(name)
    e := tocm_kms_parts(allowed[_])
    k.project == e.project
    k.location == e.location
    k.key_ring == e.key_ring
    k.key == e.key
    e.version != ""
    k.version == e.version
}
# --- toc-match end: kms v1 ---

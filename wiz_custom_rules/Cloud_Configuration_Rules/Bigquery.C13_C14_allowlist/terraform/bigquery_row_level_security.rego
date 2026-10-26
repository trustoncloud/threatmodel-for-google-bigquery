package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Domains whose identities may be granted row access.
authorized_domains := {
    "yourcompany.com",
    "subsidiary.com",
    "gserviceaccount.com"
}

# --- Helpers ---
blocked_public_principals := {"allUsers", "allAuthenticatedUsers"}

grantee_authorized(g) {
    not blocked_public_principals[g]
    parts := split(g, "@")
    count(parts) == 2
    domain := authorized_domains[_]
    endswith(parts[1], domain)
}

# --- Logic ---
# Finding: row access policy granting rows to an unauthorized identity.
WizPolicy[result] {
    document := input.document[i]
    rap := document.resource.google_bigquery_row_access_policy[name]
    grantee := rap.grantees[gidx]
    not grantee_authorized(grantee)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_row_access_policy",
        "resourceName": terraLib.get_resource_name(rap, name),
        "searchKey": sprintf("google_bigquery_row_access_policy[%s].grantees[%d]", [name, gidx]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("grantees must belong to authorized domains: %v", [authorized_domains]),
        "keyActualValue": sprintf("grantee '%v' is not authorized", [grantee]),
        "resourceTags": object.get(rap, "labels", {}),
    }
}

package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Clouds authorized for BigQuery Omni connections. Empty set = no Omni.
authorized_omni_clouds := {
    # "AWS",
    # "AZURE"
}

# --- Logic ---
# Finding: connection to AWS without authorization.
WizPolicy[result] {
    document := input.document[i]
    conn := document.resource.google_bigquery_connection[name]
    conn.aws
    not authorized_omni_clouds["AWS"]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_connection",
        "resourceName": terraLib.get_resource_name(conn, name),
        "searchKey": sprintf("google_bigquery_connection[%s].aws", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("Omni connections must match the authorized cloud list: %v", [authorized_omni_clouds]),
        "keyActualValue": "connection targets AWS (BigQuery Omni)",
        "resourceTags": object.get(conn, "labels", {}),
    }
}

# Finding: connection to Azure without authorization.
WizPolicy[result] {
    document := input.document[i]
    conn := document.resource.google_bigquery_connection[name]
    conn.azure
    not authorized_omni_clouds["AZURE"]

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_connection",
        "resourceName": terraLib.get_resource_name(conn, name),
        "searchKey": sprintf("google_bigquery_connection[%s].azure", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("Omni connections must match the authorized cloud list: %v", [authorized_omni_clouds]),
        "keyActualValue": "connection targets Azure (BigQuery Omni)",
        "resourceTags": object.get(conn, "labels", {}),
    }
}

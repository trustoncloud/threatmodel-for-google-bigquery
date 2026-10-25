package wiz

import data.generic.terraform as terraLib

# --- Configuration ---
# Authorized email domains for primary contacts (suffix match).
authorized_contact_domains := {
    "@yourcompany.com",
    "@subsidiary.com"
}

# --- Helpers ---
contact_authorized(contact) {
    domain := authorized_contact_domains[_]
    endswith(contact, domain)
}

# --- Logic ---
# Finding: exchange without a primary contact.
WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    object.get(ex, "primary_contact", "") == ""

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].primary_contact", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "every exchange must set primary_contact",
        "keyActualValue": "primary_contact is not set",
        "resourceTags": object.get(ex, "labels", {}),
    }
}

# Finding: exchange contact from an unauthorized domain.
WizPolicy[result] {
    document := input.document[i]
    ex := document.resource.google_bigquery_analytics_hub_data_exchange[name]
    contact := object.get(ex, "primary_contact", "")
    contact != ""
    not contact_authorized(contact)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_data_exchange",
        "resourceName": terraLib.get_resource_name(ex, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_data_exchange[%s].primary_contact", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("primary_contact must use an authorized domain: %v", [authorized_contact_domains]),
        "keyActualValue": sprintf("primary_contact is '%v'", [contact]),
        "resourceTags": object.get(ex, "labels", {}),
    }
}

# Finding: listing without a primary contact.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    object.get(l, "primary_contact", "") == ""

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].primary_contact", [name]),
        "issueType": "MissingAttribute",
        "keyExpectedValue": "every listing must set primary_contact",
        "keyActualValue": "primary_contact is not set",
        "resourceTags": object.get(l, "labels", {}),
    }
}

# Finding: listing contact from an unauthorized domain.
WizPolicy[result] {
    document := input.document[i]
    l := document.resource.google_bigquery_analytics_hub_listing[name]
    contact := object.get(l, "primary_contact", "")
    contact != ""
    not contact_authorized(contact)

    result := {
        "documentId": document.id,
        "resourceType": "google_bigquery_analytics_hub_listing",
        "resourceName": terraLib.get_resource_name(l, name),
        "searchKey": sprintf("google_bigquery_analytics_hub_listing[%s].primary_contact", [name]),
        "issueType": "IncorrectValue",
        "keyExpectedValue": sprintf("primary_contact must use an authorized domain: %v", [authorized_contact_domains]),
        "keyActualValue": sprintf("primary_contact is '%v'", [contact]),
        "resourceTags": object.get(l, "labels", {}),
    }
}

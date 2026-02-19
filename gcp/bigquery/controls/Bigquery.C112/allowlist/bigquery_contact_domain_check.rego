package wiz

# --- Configuration ---
# List of authorized email domains for primary contacts.
# Example: ["@yourcompany.com", "@trusted-partner.org"]
authorized_domains := {
    "@yourcompany.com", 
    "@subsidiary.com"
}

# --- Logic ---
default result := "pass"

# Target both Data Exchanges and Listings
is_target_resource {
    input.type == "google_bigquery_analytics_hub_data_exchange"
}
is_target_resource {
    input.type == "google_bigquery_analytics_hub_listing"
}

# Helper: Get the primary contact (if it exists)
get_contact = contact {
    contact := object.get(input.properties, "primaryContact", "")
    contact != ""
}

# Helper: Check if contact matches ANY authorized domain
is_domain_authorized(contact) {
    domain := authorized_domains[_]
    endswith(contact, domain)
}

# Failure: Contact exists but domain is NOT authorized
fail_unauthorized_contact {
    is_target_resource
    contact := get_contact
    
    # Validation
    not is_domain_authorized(contact)
}

# --- Aggregation ---
result := "skip" {
    not is_target_resource
} else := "fail" {
    fail_unauthorized_contact
}

# --- Metadata ---
current_contact := object.get(input.properties, "primaryContact", "None")

currentConfiguration := sprintf("Primary Contact is '%v'", [current_contact]) {
    fail_unauthorized_contact
} else := "Primary Contact uses an authorized domain"

expectedConfiguration := "Data Exchanges and Listings must use primary contacts from authorized domains."
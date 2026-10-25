package wiz

# --- Configuration ---
# List of authorized email domains for primary contacts.
# Example: ["@yourcompany.com", "@trusted-partner.org"]
authorized_contact_domains := {
    "@yourcompany.com",
    "@subsidiary.com"
}

# --- Logic ---
default result := "pass"

# Exchange payloads use snake_case fields and carry the full path in name.
# (Listings are not an ingested CCR type; their contact check rides the
# Terraform matcher.)
is_exchange {
    contains(object.get(input, "name", ""), "/dataExchanges/")
}

# Helper: Get the primary contact (unset arrives as "")
get_contact = contact {
    contact := object.get(input, "primary_contact", "")
    contact != ""
}

# Helper: Check if contact matches ANY authorized domain
is_domain_authorized(contact) {
    domain := authorized_contact_domains[_]
    endswith(contact, domain)
}

# Failure 1: No primary contact set
fail_missing_contact {
    object.get(input, "primary_contact", "") == ""
}

# Failure 2: Contact exists but domain is NOT authorized
fail_unauthorized_contact {
    contact := get_contact
    not is_domain_authorized(contact)
}

# --- Aggregation ---
result := "skip" {
    not is_exchange
} else := "fail" {
    fail_missing_contact
} else := "fail" {
    fail_unauthorized_contact
}

# --- Metadata ---
currentConfiguration := "No Primary Contact is set" {
    fail_missing_contact
} else := sprintf("Primary Contact is '%v'", [object.get(input, "primary_contact", "")]) {
    fail_unauthorized_contact
} else := "Primary Contact is set and uses an authorized domain"

expectedConfiguration := "Every Data Exchange must have a primary contact from an authorized domain."

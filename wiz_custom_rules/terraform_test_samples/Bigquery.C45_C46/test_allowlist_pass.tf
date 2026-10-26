# Bigquery.C46 (bigquery_data_policy_iam) - allowlist - COMPLIANT

resource "google_bigquery_datapolicy_data_policy_iam_member" "masked_reader" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  member         = "serviceAccount:masked-reader@my-project.iam.gserviceaccount.com"
}

resource "google_bigquery_datapolicy_data_policy_iam_binding" "scientists" {
  location       = "us"
  data_policy_id = "pii_masking_policy"
  role           = "roles/bigquerydatapolicy.maskedReader"
  members = [
    "group:data-scientists@example.com"
  ]
}

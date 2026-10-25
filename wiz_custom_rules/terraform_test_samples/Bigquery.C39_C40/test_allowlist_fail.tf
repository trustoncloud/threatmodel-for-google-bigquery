# Bigquery.C40 (bigquery_omni_governance) - allowlist - VIOLATING

# AWS Omni connection while the authorized cloud list is empty: 1 finding
resource "google_bigquery_connection" "aws_link" {
  connection_id = "aws_link"
  location      = "aws-us-east-1"

  aws {
    access_role {
      iam_role_id = "arn:aws:iam::123456789012:role/bigquery-omni"
    }
  }
}

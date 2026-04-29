# ThreatModel for Google BigQuery
A library of all the attack scenarios on Google BigQuery, and how to mitigate them following a risk-based approach 

## Interactive version
Find an interactive version of this content: https://demo.app.trustoncloud.com/threatmodel/gcp/bigquery

## Detection-engineering compiler (`tools/threatmodel_compiler/`)

`threatmodel-gcp-bigquery.json` doubles as an intermediate representation that
compiles into multi-target detection content: BigQuery-native scheduled queries
(+ Terraform), Chronicle YARA-L 2.0, Splunk SPL, Microsoft Sentinel KQL, and a
MITRE ATT&CK Navigator coverage layer. See [tools/threatmodel_compiler/README.md](tools/threatmodel_compiler/README.md)
and the generated [detections/](detections/) tree (regenerated on every release tag by `.github/workflows/compile-detections.yml`).

## Contact
Email [contact@trustoncloud.com](mailto:contact@trustoncloud.com) or use GitHub issues

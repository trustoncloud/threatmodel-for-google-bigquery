# BigQuery Threat Coverage Matrix

Auto-generated from `threatmodel-gcp-bigquery.json` and the artifacts in this directory.

## Repo-level posture

- Wiz custom controls present: **34**
- GCP custom org constraints present: **yes**
- Compiler-emitted detections (this PR): **3 threats**

## Per-threat coverage

| Threat | Name | Tactic | Severity | Prevent (existing) | Detect (existing) | Detect (compiled) |
|---|---|---|---|---|---|---|
| Bigquery.T1 | Destruction of data by deleting dataset or table | TA0040 | Low | yes | — | +bigquery_sql, +chronicle, +splunk, +sentinel |
| Bigquery.T2 | Unauthorized access to data by changing connection configurations | TA0001 | Medium | yes | — | — |
| Bigquery.T3 | Loss of integrity and availability by copying datasets and overwriting the desti… | TA0040 | Medium | yes | — | — |
| Bigquery.T4 | Loss of the integrity of the training model | TA0040 | Medium | yes | yes (config) | — |
| Bigquery.T5 | Loss of integrity and availability by appending or overwriting data, or by creat… | TA0040 | Medium | yes | yes (config) | — |
| Bigquery.T6 | Exfiltration of data by exporting tables to other services | TA0010 | Medium | yes | — | +bigquery_sql, +chronicle, +splunk, +sentinel |
| Bigquery.T8 | Loss of integrity and availability by manipulating data using routines | TA0040 | Medium | yes | — | — |
| Bigquery.T9 | Escalate privileges, loss of availability or integrity of data, or exfiltrate da… | TA0010 | High | yes | yes (config) | +bigquery_sql, +chronicle, +splunk, +sentinel |
| Bigquery.T10 | Restricting access to resources by modifying privileges | TA0004 | Medium | yes | — | — |
| Bigquery.T11 | Disruption of application functionality by modification of table and view config… | TA0040 | Medium | yes | — | — |
| Bigquery.T12 | Denial of Service/Denial of Wallet by removing/creating reservations | TA0040 | Medium | yes | yes (config) | — |
| Bigquery.T13 | Data exfiltration by updating the destination dataset in transfer and transfer c… | TA0010 | Medium | yes | yes (config) | — |
| Bigquery.T14 | Loss of data during recovery by deleting a snapshot | TA0040 | Medium | yes | — | — |
| Bigquery.T15 | Data exfiltration by exporting query results | TA0010 | Medium | yes | — | — |
| Bigquery.T17 | Unauthorized access to the table columns by adding or removing policy tags | TA0004 | Medium | yes | — | — |
| Bigquery.T18 | BigQuery ML model exfiltration | TA0010 | Medium | yes | — | — |
| Bigquery.T19 | Table exfiltration by cloning | TA0010 | Medium | yes | — | — |
| Bigquery.T20 | Exfiltration of query results to an unauthorized destination table and bucket | TA0010 | Medium | yes | — | — |
| Bigquery.T21 | Misconfiguration of a dataset causing loss of integrity and availability, or pri… | TA0004 | Medium | yes | — | — |
| Bigquery.T22 | Permanent loss of a BigQuery ML model by modifying its expiration time | TA0040 | Medium | yes | — | — |
| Bigquery.T24 | Importing malicious models in BigQuery | TA0002 | Medium | yes | — | — |
| Bigquery.T25 | Misconfiguration of a table to cause loss of integrity and availability | TA0040 | Medium | yes | — | — |
| Bigquery.T26 | Unauthorized access to cached data from the last 24 hours | TA0010 | Low | yes | — | — |
| Bigquery.T27 | Loss of data integrity by restoring a snapshot | TA0040 | Medium | yes | — | — |
| Bigquery.T28 | Unauthorized access to listings by setting permissions | TA0004 | Medium | yes | — | — |
| Bigquery.T29 | Denial of Service by revoking subscriptions | TA0040 | Low | yes | — | — |
| Bigquery.T30 | Unauthorized access to contents of a listing | TA0010 | Medium | yes | — | — |
| Bigquery.T31 | Discovery of BigQuery sharing resources | TA0007 | Low | yes | — | — |
| Bigquery.T32 | Denial of Service by deleting data exchanges, listings, or subscriptions | TA0040 | Low | yes | — | — |
| Bigquery.T33 | Email leakage via malicious listing | TA0010 | Low | yes | — | — |
| Bigquery.T34 | Denial of Service via unauthorized continuous query cancellation | TA0040 | Low | yes | — | — |
| Bigquery.T35 | Expose sensitive data via auto-enabled Gemini API | TA0010 | Low | yes | — | — |
| Bigquery.T36 | Data corruption via unauthorized hard failover | TA0040 | Low | yes | yes (config) | — |

## Notes on existing 'Detect' controls

The repo's existing NIST CSF `Detect` controls are implemented as Rego config-posture checks (Wiz custom rules). These verify *configuration drift* and *policy violations*, not *behavioral signals from audit logs*. The compiler's `Detect (compiled)` column covers behavioral detection content (BigQuery SQL, Chronicle YARA-L, Splunk SPL, Sentinel KQL) generated from the same source-of-truth JSON.


# GCP BigQuery Customised CCRs for Wiz

30 Wiz custom configuration rules covering GCP BigQuery assurance controls
from the TrustOnCloud GCP BigQuery ThreatModel. Each rule checks your live
GCP estate (Cloud matcher), your Terraform code before deployment (Terraform
matcher), or both. Every rule is test-validated, with property paths verified
against real Wiz payloads, the Google API discovery documents, and the
Terraform google provider documentation.

These rules are gap-fillers: each covers an assurance control that Wiz's
built-in CCR library does not address. Severities follow the ThreatModel
weighted priority.

---

## Rule naming: two control IDs per rule

Every rule folder carries two control IDs, for example
`Bigquery.C4_C5_allowlist`:

- The **first ID** is the paired Directive control. The Terraform matcher
  implements it: it verifies your IaC declares the safeguard before
  deployment.
- The **second ID** is the Assurance control. Where a cloud matcher exists,
  it verifies the safeguard is live on the deployed resource.

One rule therefore covers a pre-deploy and a post-deploy control as a single
enforcement intent. Each rule's description names both IDs, the mapping CSV
carries a "Paired Control" column, and the `controlId` / `pairedControlId`
tags let you filter in the Wiz console by either ID.

A BigQuery particularity: Wiz's CCR platform ingests only a subset of
BigQuery resource types (datasets, transfer configurations, Analytics Hub
data exchanges, and projects). 17 of the 30 rules therefore
ship **Terraform-only**: their resource types (tables, jobs, connections,
reservations, row access policies, listings, policy tags, data policies, DLP
triggers) have no runtime scan surface, and the Terraform matcher is the
enforcement point. Each such rule's description states this explicitly.

Five ThreatModel assurance controls are not deliverable as rules: BigQuery
ML models (C49, C80) and the org/project settings set through DDL (C125,
C139) have neither a Wiz nor a Terraform surface, and whether an approved
query template meets its requirements (C149) is a review of its SQL. One
more, no dataset open to `allUsers` or `allAuthenticatedUsers` (C16), is
checked exactly by Wiz's built-in rule BigQuery-001. The mapping CSV records
the rationale or the built-in for each.

---

## What is in this delivery

30 controls, delivered as 38 rule folders (8 controls ship two modes).

| Rule | Severity | What it flags |
|---|---|---|
| Bigquery.C7_C8 | High | Dataset access entries (users, groups, views, routines) outside your authorized set |
| Bigquery.C13_C14 | High | Row access policies granting rows to public principals or unauthorized domains |
| Bigquery.C39_C40 | High | BigQuery Omni connections outside your requirements, and org policies weakening the Omni ban |
| Bigquery.C4_C5 | Medium | Datasets missing the backup-policy label or carrying an unauthorized schedule |
| Bigquery.C10_C11 | Medium | Policy tag (sensitive column) grants to entities outside your authorized set |
| Bigquery.C18_C19 | Medium | Datasets in unauthorized locations or with unauthorized expiration settings |
| Bigquery.C20_C21 | Medium | BigQuery DLP job triggers without an authorized inspect template (or any inspection rules) |
| Bigquery.C23_C24 | Medium | External tables, load jobs, and extract jobs moving data to or from unauthorized URIs |
| Bigquery.C27_C29 | Medium | Datasets and tables without CMEK, or using an unauthorized key or key version |
| Bigquery.C33_C34 | Medium | Tables without an expiration time (infinite retention) |
| Bigquery.C36_C37 | Medium | Sensitive columns declared as plaintext, and queries touching sensitive tables without AEAD functions |
| Bigquery.C45_C46 | Medium | Data policy (column masking) grants to members outside your authorized set |
| Bigquery.C54_C55 | Medium | Query jobs without byte limits and load jobs silently dropping unknown values |
| Bigquery.C58_C59 | Medium | BigLake metadata caches with invalid modes or staleness outside your bounds |
| Bigquery.C61_C62 | Medium | Reservations and assignments outside your authorized editions, capacity, and assignees |
| Bigquery.C67_C68 | Medium | Transfers from unauthorized sources, to unauthorized destinations, or running as unauthorized identities |
| Bigquery.C71_C72 | Medium | Query jobs loading UDF code from untrusted Cloud Storage locations |
| Bigquery.C82_C83 | Medium | Partitioned tables that do not require a partition filter |
| Bigquery.C93_C94 | Medium | Designated sensitive data exchanges not configured as Data Clean Rooms |
| Bigquery.C104_C105 | Medium | Subscriber-capable roles granted to public principals or unauthorized domains |
| Bigquery.C111_C112 | Medium | Exchanges and listings without a primary contact, or with one from an unauthorized domain |
| Bigquery.C114_C115 | Medium | Listings without full restricted export (including query results) |
| Bigquery.C117_C118 | Medium | Dataset ACLs granting public access, unauthorized domains, or missing your mandatory admin group |
| Bigquery.C76_C77 | Low | Query jobs using destructive write modes or requesting schema updates |
| Bigquery.C96_C97 | Low | Data exchanges published to the Analytics Hub marketplace without authorization |
| Bigquery.C99_C100 | Low | Listings publicly discoverable, exportable without authorization, or missing governance metadata |
| Bigquery.C51_C52 | Low | Datasets with a time travel window below your minimum |
| Bigquery.C108_C109 | Low | Linked datasets subscribed from unauthorized sources |
| Bigquery.C101_C102 | Informational | Secrets or PII patterns in listing names, descriptions, or documentation |
| Bigquery.C128_C129 | Informational | Gemini (Cloud AI Companion) enabled outside your authorized projects |

## Coverage breakdown

| Axis | Count |
|---|---|
| Controls | 30 |
| Rule folders (control x mode) | 38 |
| Rules with a cloud matcher | 13 controls (19 folders) |
| Rules with a Terraform matcher | all 30 controls (38 folders) |
| Terraform-only rules | 17 controls (no Wiz runtime surface for their types) |
| Cloud OPA tests passing | 97 of 97 |
| Terraform fixture checks passing | 76 of 76 |

Modes shipped per control:

| Modes | Rules |
|---|---|
| allowlist, universal | Bigquery.C18_C19, C20_C21, C27_C29, C39_C40, C54_C55, C93_C94, C96_C97, C128_C129 |
| universal | Bigquery.C33_C34, C51_C52, C82_C83, C114_C115 |
| denylist | Bigquery.C101_C102 |
| allowlist | all others |

- **allowlist**: flag any resource whose value is not in your authorized set.
- **denylist**: flag any resource matching the configured patterns.
- **universal**: enforce the secure state on every resource (no exceptions).

| Wiz native type | Rules |
|---|---|
| `bigquery#dataset` | Bigquery.C4_C5, C7_C8, C18_C19, C27_C29, C51_C52, C108_C109, C117_C118 |
| `bigquerydatatransfer#TransferConfig` | Bigquery.C67_C68 |
| `analyticshub#DataExchange` | Bigquery.C93_C94, C96_C97, C111_C112 |
| `project#instance` | Bigquery.C128_C129, C39_C40 |

| Terraform resource family | Rules |
|---|---|
| `google_bigquery_dataset` (+ `google_bigquery_dataset_access`) | C5, C8, C19, C29, C52, C118 |
| `google_bigquery_table` | C24, C29, C34, C37, C59, C83 |
| `google_bigquery_job` | C24, C37, C55, C72, C77 |
| Analytics Hub (exchange, listing, subscription, IAM) | C94, C97, C100, C102, C105, C109, C112, C115 |
| IAM trios (policy tags, data policies) | C11, C46 |
| `google_bigquery_connection` + org policy resources (new and legacy) | C40 |
| `google_bigquery_reservation` (+ assignment) | C62 |
| `google_bigquery_data_transfer_config` | C68 |
| `google_bigquery_row_access_policy` | C14 |
| `google_data_loss_prevention_job_trigger` | C21 |
| `google_project_service` | C129 |

Terraform matchers cover both declaration forms wherever GCP offers them:
inline dataset `access` blocks AND standalone `google_bigquery_dataset_access`
resources; IAM `_iam_policy`, `_iam_binding`, AND `_iam_member` resources.

---

## Package layout

```
gcp-bigquery/
├── Cloud_Configuration_Rules/          The deployable rules (38 folders)
│   └── Bigquery.<parent>_<assurance>_<mode>/
│       ├── cloud/<rule>.rego           Cloud matcher (runtime), where applicable
│       ├── terraform/<rule>.rego       Terraform matcher (IaC)
│       └── metadata/
│           ├── metadata.json           Name, severity, native types, tags
│           ├── description.md
│           └── remediation.md
├── terraform_test_samples/             Sample .tf for self-validation,
│   └── Bigquery.<parent>_<assurance>/  keyed to match the rule folders
│       └── test_<mode>_{pass,fail}.tf
├── main.tf                             Wiz Terraform module (reads Cloud_Configuration_Rules/)
├── providers.tf                        Wiz provider + auth instructions
├── versions.tf
├── GCP BigQuery Controls and Wiz Mapping.csv
└── README.md                           This document
```

---

## Versioning

Versions are repo-wide rather than per service, and follow a semver-lite scheme:

- A minor bump, `v0.X.0`, means new rule coverage: a new service, or wider
  coverage of one already published.
- A patch bump, `v0.X.Y`, means fixes to rules already shipped.

Because the version covers the whole repository, a release names the one service
it updates and leaves every other package unchanged. A package downloaded from a
GitHub release carries its service and version in its filename.

---

## Deploying to Wiz

### 1. Create a Wiz service account

In Wiz: Settings -> Access Management -> Service Accounts. Use type
"Custom Integration (GraphQL API)". Tick all permission boxes under the
"Cloud Configuration Rule" and "Cloud Configuration" sections.

### 2. Set credentials

```bash
export WIZ_URL="https://api.<host>.app.wiz.io/graphql"   # Tenant Info -> API Endpoint URL
export WIZ_CLIENT_ID=<your_wiz_client_id>
export WIZ_CLIENT_SECRET=<your_wiz_client_secret>
```

### 3. Apply

```bash
terraform init
terraform plan      # review what will be created
terraform apply
```

`terraform destroy` removes the rules cleanly if you want to back them out.

---

## Before you apply

### Enablement posture

- **Universal-mode rules ship enabled.** They enforce a fixed secure state,
  carry no placeholders, and produce real findings on the first scan.
- **Allowlist and denylist rules ship disabled.** They depend on your
  environment-specific values and stay dormant until you set those values and
  enable them. This avoids a first-scan flood of placeholder-driven findings.

To enable an allowlist rule after configuring it, toggle it in the Wiz UI, or
set `"enabled": true` in that rule's `metadata/metadata.json` and re-run
`terraform apply`.

### Replace placeholder allowlist values

Allowlist rules carry placeholder values under a `--- Configuration ---`
comment block at the top of each `.rego` file. Set your organization's values
in BOTH the cloud and terraform matcher of the same rule, and keep them in
sync. Note that some pairs identify the same resource differently: cloud
matchers see full resource names carrying project NUMBERS (e.g.
`projects/123456789012/locations/us/dataExchanges/x`), while Terraform
matchers key on the declared ids (e.g. the `data_exchange_id` argument).

| Rule | Set this |
|---|---|
| Bigquery.C4_C5 | Backup label key and authorized schedule values |
| Bigquery.C7_C8 | Authorized dataset access entities, including Google service agents (see notes) |
| Bigquery.C10_C11 | Authorized entities for policy tags (sensitive columns) |
| Bigquery.C13_C14 | Authorized domains for row access grantees |
| Bigquery.C18_C19 | Authorized locations and expiration values |
| Bigquery.C20_C21 | Authorized DLP inspect template names |
| Bigquery.C23_C24 | Authorized source and destination URI prefixes |
| Bigquery.C27_C29 | Authorized CMEK keys (key-level or pinned versions) |
| Bigquery.C36_C37 | Sensitive columns per table AND sensitive table references (keep aligned) |
| Bigquery.C39_C40 | Authorized Omni clouds (terraform) and authorized Omni projects (cloud) |
| Bigquery.C45_C46 | Authorized members for data policies |
| Bigquery.C58_C59 | Metadata cache staleness bounds |
| Bigquery.C61_C62 | Authorized editions, capacity ceiling, job types, and assignees |
| Bigquery.C67_C68 | Authorized sources, destination datasets, run identities, and GCS path prefixes |
| Bigquery.C71_C72 | Trusted UDF bucket prefixes |
| Bigquery.C76_C77 | Authorized write dispositions |
| Bigquery.C93_C94 | Exchanges required to be Data Clean Rooms |
| Bigquery.C96_C97 | Exchanges authorized for marketplace publication |
| Bigquery.C99_C100 | Listings allowed to be exportable |
| Bigquery.C101_C102 | Sensitive-content regex patterns (denylist) |
| Bigquery.C104_C105 | Authorized subscriber domains |
| Bigquery.C108_C109 | Authorized subscription source exchanges (terraform) and source dataset patterns by project NUMBER (cloud) |
| Bigquery.C111_C112 | Authorized primary-contact domains |
| Bigquery.C117_C118 | Authorized domains, the public members to block, and the mandatory admin entity |
| Bigquery.C128_C129 | Projects authorized to use Gemini |

### Notes on specific rules

- **Terraform-only rules (17 of 30)**: Wiz's CCR platform does not ingest
  BigQuery tables, jobs, models, connections, reservations, row access
  policies, Analytics Hub listings, policy tags, data policies, or DLP
  triggers. For controls on those types, the Terraform matcher is the
  enforcement point and there are no runtime findings.
- **The job rules (C54_C55, C71_C72, C76_C77, C36_C37, C23_C24 job legs)**
  cover `google_bigquery_job` resources declared in Terraform. Ad hoc queries
  submitted at runtime are not visible to any Wiz scan; pair these rules with
  query-history auditing (region `INFORMATION_SCHEMA.JOBS`) for runtime
  assurance.
- **Bigquery.C7_C8**: GCP adds Google service agents to dataset ACLs when you
  enable services (for example the Data Transfer agent
  `service-<projectNumber>@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com`
  becomes a WRITER on transfer destinations). Add the agents you use to the
  allowlist, or standing findings will appear on those datasets.
- **Bigquery.C117_C118** allowlists domains rather than exact entities; its
  placeholder includes `gserviceaccount.com`, which passes ALL service
  accounts. Convenient, but coarse: for tight control of service accounts use
  C7_C8's exact entries and narrow the domain list here.
- **Bigquery.C104_C105** scans all three IAM declaration forms. Do not manage
  the same resource with `_iam_policy` AND `_iam_binding`/`_iam_member`
  together; Terraform applies will fight over the policy. Pick one form per
  resource.
- **Bigquery.C111_C112** fails exchanges and listings with NO primary
  contact, by design.
- **Bigquery.C39_C40 (universal)** verifies the Omni-disable constraints on
  every project's effective policies: constraints inherited from the
  organization are visible on project payloads, so org-governed projects pass
  correctly and a project-level override fails. The Terraform matcher additionally flags declared weakening
  through both the current `google_org_policy_policy` and the legacy
  organization-policy resources.
- **Bigquery.C36_C37** checks two build-time surfaces: designated sensitive
  columns must be typed BYTES (AEAD ciphertext) in declared table schemas,
  and declared queries touching sensitive tables must use the AEAD function
  family (`AEAD.ENCRYPT`, `DETERMINISTIC_ENCRYPT`). Queries reaching data
  through views or dynamic SQL are outside text-matching reach.
- **Bigquery.C4_C5** verifies backup governance through dataset labels; the
  ThreatModel control also names tables and models, which have no scan
  surface, so datasets carry the governance signal for the control.
- **Bigquery.C96_C97**: `discovery_type` distinguishes marketplace-published
  exchanges (PUBLIC) from private ones; an exchange with no discovery type is
  not published and passes.

---

## Self-verification

`terraform_test_samples/` contains pass and fail Terraform samples for every
rule, in folders named to match the rule folders. Upload a `_fail.tf` sample
through your Wiz IaC scan (CLI or CI integration) and confirm the
corresponding rule produces a finding; the `_pass.tf` sample should scan
clean. Allowlist samples align with the shipped placeholder values, so
validate them before replacing the placeholders (or update the samples to
your values).

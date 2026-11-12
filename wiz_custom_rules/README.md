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
data exchanges, listings and subscriptions, and projects). 13 of the 30 rules
therefore ship **Terraform-only**: their resource types (tables, jobs,
connections, reservations, row access policies, policy tags, data policies,
DLP triggers) have no runtime scan surface, and the Terraform matcher is the
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

30 controls, delivered as 39 rule folders (8 controls ship two modes, and
Bigquery.C108_C109 ships a second rule for subscriptions).

| Rule | Severity | What it flags |
|---|---|---|
| Bigquery.C7_C8 | High | Dataset access entries (users, groups, and views, routines and datasets by project, dataset and ID) outside your authorized set |
| Bigquery.C13_C14 | High | Row access policies granting rows to public principals or to grantees that are not approved |
| Bigquery.C39_C40 | High | BigQuery Omni connections outside your requirements, and org policies weakening the Omni ban |
| Bigquery.C4_C5 | Medium | Datasets missing the backup-schedule label or carrying an unauthorized schedule (the label is no proof of a backup) |
| Bigquery.C10_C11 | Medium | Policy tag and taxonomy grants, and the Fine-Grained Reader role on a project, folder or organization, to entities outside your authorized set |
| Bigquery.C18_C19 | Medium | Datasets in unauthorized locations or with unauthorized expiration settings |
| Bigquery.C20_C21 | Medium | BigQuery DLP job triggers without an authorized inspect template (or any inspection rules); redaction and trigger coverage are not checked |
| Bigquery.C23_C24 | Medium | External tables and load jobs reading from sources that are not approved, extract jobs writing to destinations that are not approved, and load, extract, copy and query jobs reading or writing tables that are not approved |
| Bigquery.C27_C29 | Medium | Datasets without a default CMEK or with a key that is not approved, and Terraform tables with no key of their own and none to inherit |
| Bigquery.C33_C34 | Medium | Tables with no expiration time of their own and no dataset default to inherit (infinite retention) |
| Bigquery.C36_C37 | Medium | Sensitive columns declared with a type other than BYTES, and queries naming sensitive tables that call no AEAD function |
| Bigquery.C45_C46 | Medium | Data policy (column masking) grants, and the Masked Reader role on a project, folder or organization, to members outside your authorized set |
| Bigquery.C54_C55 | Medium | Query jobs without byte limits and load jobs silently dropping unknown values |
| Bigquery.C58_C59 | Medium | BigLake metadata caches with invalid modes or staleness outside your bounds |
| Bigquery.C61_C62 | Medium | Reservations and assignments outside your authorized editions, capacity (baseline plus autoscale), assignees, and reservations |
| Bigquery.C67_C68 | Medium | Transfers from unauthorized sources, to unauthorized destinations (project and dataset), running as unauthorized or unknown identities, or reading outside approved buckets |
| Bigquery.C71_C72 | Medium | Query jobs loading UDF code from untrusted Cloud Storage locations |
| Bigquery.C82_C83 | Medium | Partitioned tables, Hive-partitioned external tables included, that do not require a partition filter |
| Bigquery.C93_C94 | Medium | Designated sensitive data exchanges not configured as Data Clean Rooms |
| Bigquery.C104_C105 | Medium | Subscriptions held by accounts outside your authorized subscribers, and subscriber-capable roles granted to public principals or to members outside them |
| Bigquery.C111_C112 | Medium | Exchanges and listings without a primary contact, or with one from an unauthorized domain |
| Bigquery.C114_C115 | Medium | Listings of a BigQuery dataset without full restricted export (including query results) |
| Bigquery.C117_C118 | Medium | Dataset access granting public access or members that are not approved, or missing your mandatory admin group |
| Bigquery.C76_C77 | Low | Query jobs using destructive write modes, create modes that are not approved, or requesting schema updates (the query text is not read) |
| Bigquery.C96_C97 | Low | Data exchanges published to the Analytics Hub marketplace without authorization |
| Bigquery.C99_C100 | Low | Listings publicly discoverable (set on the listing or inherited from its exchange), exportable without authorization, or missing governance metadata |
| Bigquery.C51_C52 | Low | Datasets with a time travel window below your minimum |
| Bigquery.C108_C109 | Low | Subscriptions and their linked datasets from unauthorized sources or in unauthorized projects |
| Bigquery.C101_C102 | Informational | Secrets or PII patterns in listing names, descriptions, or documentation |
| Bigquery.C128_C129 | Informational | Gemini (Cloud AI Companion) enabled outside your authorized projects |

## Coverage breakdown

| Axis | Count |
|---|---|
| Controls | 30 |
| Rule folders (control x mode, plus one for subscriptions) | 39 |
| Rules with a cloud matcher | 17 controls (24 folders) |
| Rules with a Terraform matcher | all 30 controls (38 folders) |
| Terraform-only rules | 13 controls (no Wiz runtime surface for their types) |
| Cloud OPA tests passing | 248 of 248 |
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
| `analyticshub#listing` | Bigquery.C99_C100, C101_C102, C114_C115 |
| `analyticshub#subscription` | Bigquery.C104_C105, C108_C109 (its subscriptions rule) |
| `project#instance` | Bigquery.C128_C129, C39_C40 |

| Terraform resource family | Rules |
|---|---|
| `google_bigquery_dataset` (+ `google_bigquery_dataset_access`) | C5, C8, C19, C29, C52, C118 |
| `google_bigquery_dataset_iam_member`, `_binding`, `_policy` | C8, C118 |
| `google_bigquery_table_iam_member`, `_binding`, `_policy` | C8 |
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
├── Cloud_Configuration_Rules/          The deployable rules (39 folders)
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
├── pack.json                           Manifest for the ThreatModel Assurance module
├── GCP BigQuery Controls and Wiz Mapping.csv
└── README.md                           This document
```

---

## Versioning

Versions are repo-wide rather than per service, and follow a semver-lite scheme:

- A minor bump, `v0.X.0`, means a new service.
- A patch bump, `v0.X.Y`, means a change to a service already published: new
  rules, wider coverage, or fixes to rules already shipped.

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
names a project by its ID. Those Terraform lists end in `_by_project_id`
and take the same full name with the project ID (e.g.
`projects/my-project/locations/us/dataExchanges/x`). A Terraform resource
is matched to such a list only when it sets `project` to a literal value:
the provider's default project and a project taken from a variable are not
in the source, so they are never approved. The exception is a variable that
declares a default: the scan reads the Terraform source, so it checks that
default. Terraform can deploy a value passed in its place, and a passing
scan does not cover that value.

| Rule | Set this |
|---|---|
| Bigquery.C4_C5 | Backup label key and authorized schedule values |
| Bigquery.C7_C8 | Authorized dataset access entities, including Google service agents (see notes). Views, routines and datasets are written `view:<project-id>.<dataset>.<table>`, `routine:<project-id>.<dataset>.<routine>` and `dataset:<project-id>.<dataset>` |
| Bigquery.C10_C11 | Authorized entities for policy tags, taxonomies and the Fine-Grained Reader role |
| Bigquery.C13_C14 | Approved row access grantees: domains, exact emails, and service accounts by exact address or project ID |
| Bigquery.C18_C19 | Authorized locations and expiration values |
| Bigquery.C20_C21 | Authorized DLP inspect template names |
| Bigquery.C23_C24 | Approved Cloud Storage sources, approved Cloud Storage export destinations, approved hosts for other sources, and approved source and destination tables by full name with the project ID |
| Bigquery.C27_C29 | Approved CMEK keys, by full key name without a version |
| Bigquery.C36_C37 | Sensitive columns per table, keyed `dataset.table`, AND sensitive table references (keep aligned) |
| Bigquery.C39_C40 | Projects authorized to use Omni, by project ID (the same list in both matchers) |
| Bigquery.C45_C46 | Authorized members for data policies and the Masked Reader role |
| Bigquery.C58_C59 | Metadata cache staleness bounds |
| Bigquery.C61_C62 | Authorized editions, capacity ceiling (baseline plus autoscale), job types, assignees, and approved reservations by full name with the project ID |
| Bigquery.C67_C68 | Authorized sources, destinations as `projects/<project>/datasets/<dataset>` (project number in the cloud matcher, project ID in Terraform), run identities, and approved Cloud Storage buckets or folders |
| Bigquery.C71_C72 | Trusted UDF buckets or bucket folders |
| Bigquery.C76_C77 | Authorized write dispositions and create dispositions |
| Bigquery.C93_C94 | Exchanges required to be Data Clean Rooms, by full name (project number in the cloud matcher, project ID in Terraform) |
| Bigquery.C96_C97 | Exchanges authorized for marketplace publication, by full name (project number in the cloud matcher, project ID in Terraform) |
| Bigquery.C99_C100 | Listings allowed to be exportable (by listing ID in Terraform, by full name with the project number in the cloud matcher), and private exchanges declared outside the scanned files, by full name with the project ID |
| Bigquery.C101_C102 | Sensitive-content regex patterns (denylist) |
| Bigquery.C104_C105 | Authorized subscribers (domains, exact emails, and service accounts by exact address or project ID), and projects that may hold a subscription to a whole exchange, by project ID (cloud) |
| Bigquery.C108_C109 | Authorized source exchanges and listings by full name, with the project ID in Terraform and the project NUMBER in the cloud matcher; source dataset patterns by project NUMBER (cloud); authorized subscriber projects by project ID (both), and by project NUMBER for a subscription that names only its linked dataset (cloud) |
| Bigquery.C111_C112 | Authorized primary-contact domains |
| Bigquery.C117_C118 | Approved access members (domains, exact emails, and service accounts by exact address or project ID), the public members to block, and the mandatory admin entity |
| Bigquery.C128_C129 | Projects authorized to use Gemini |

### Notes on specific rules

- **Terraform-only rules (13 of 30)**: Wiz's CCR platform does not ingest
  BigQuery tables, jobs, models, reservations, row access policies, policy
  tags, or data policies. It does ingest BigQuery connections and DLP job
  triggers, which this pack has no cloud matcher for yet. For controls on all
  of these types, the Terraform matcher is the enforcement point and there
  are no runtime findings.
- **Analytics Hub cloud matchers (C93_C94, C96_C97, C99_C100, C101_C102,
  C104_C105, C108_C109, C111_C112, C114_C115)** read exchanges, listings and
  subscriptions in single-region locations. Resources in the multi-region
  `us` were not present in the scanned data when checked, so rely on the
  Terraform matchers for multi-region exchanges.
- **Bigquery.C108_C109** ships two rules from one cloud matcher, because a
  rule evaluates one resource type. `Bigquery.C108_C109 - ... (allowlist)`
  reads linked datasets and carries the Terraform matcher; `(allowlist,
  subscriptions)` reads subscriptions and approves each by the exchange or
  listing it is to, its own project and the project of the dataset it links.
  A linked dataset does not name its listing, so only the subscriptions rule
  compares exchanges and listings at runtime. The two rule folders each carry
  their own copy of the cloud matcher,
  `Bigquery.C108_C109_allowlist/cloud/bigquery_subscription_ingress.rego` and
  `Bigquery.C108_C109_allowlist_subscriptions/cloud/bigquery_subscription_ingress.rego`:
  set the configuration block in both, with the same values. The dataset
  rule reads `authorized_source_dataset_patterns`,
  `internal_project_pattern` and `authorized_subscriber_project_ids`; the
  subscriptions rule reads `authorized_source_exchange_names`,
  `authorized_source_listing_names`, `authorized_subscriber_project_ids` and
  `authorized_subscriber_project_numbers`. `authorized_subscriber_project_ids`
  is also in the Terraform matcher of the dataset rule, so it is set in three
  places. A subscription that states the project ID of its destination
  dataset is checked against `authorized_subscriber_project_ids`; one that
  only names its linked dataset carries a project number, checked against
  `authorized_subscriber_project_numbers`; a dataset subscription that
  states neither is reported. A cancelled or revoked subscription is
  skipped.
- **The job rules (C54_C55, C71_C72, C76_C77, C36_C37, C23_C24 job legs)**
  cover `google_bigquery_job` resources declared in Terraform. Ad hoc queries
  submitted at runtime are not visible to any Wiz scan; pair these rules with
  query-history auditing (region `INFORMATION_SCHEMA.JOBS`) for runtime
  assurance.
- **Bigquery.C7_C8**: GCP adds Google service agents to dataset ACLs when you
  enable services (for example the Data Transfer agent
  `service-<projectNumber>@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com`
  becomes a WRITER on transfer destinations). Add the agents you use to the
  allowlist, or standing findings will appear on those datasets. List a
  service account as `user:<email>`, the way the dataset access list files
  it; the same entry approves it in dataset and table IAM grants, which the
  Terraform matcher also reads. Table and view IAM has no runtime scan
  surface, so those grants are checked in Terraform only.
- **Bigquery.C117_C118 and C13_C14** approve users, groups and domain-wide
  grants by domain or exact email, and service accounts by exact address or
  by the project that owns them (`project_ids`). A domain never approves a
  service account, and `yourcompany.com` does not approve its subdomains
  (add `*.yourcompany.com`). Google service agents are approved only by exact
  address. The Terraform matcher of C117_C118 reads inline `access` blocks,
  `google_bigquery_dataset_access` and the three dataset IAM resources.
- **Bigquery.C67_C68** approves a destination by project and dataset
  together, so the Terraform resource must set `project` to a literal value.
  Cloud Storage sources are approved by exact bucket, or by folder inside a
  bucket. A transfer with no run identity reported is a finding. The SQL of a
  scheduled query is not read: a query can read other tables, change data or
  export results whatever its destination dataset is, so review scheduled
  queries separately.
- **Bigquery.C104_C105** scans all three IAM declaration forms. Do not manage
  the same resource with `_iam_policy` AND `_iam_binding`/`_iam_member`
  together; Terraform applies will fight over the policy. Pick one form per
  resource. Its cloud matcher reads the subscriptions that exist and checks
  the account that subscribed against the same list. A cancelled or revoked
  subscription is skipped. A subscription belongs
  to the subscriber's project, so a subscriber in a project that is not
  scanned does not appear, and a grant of the subscriber role is read by the
  Terraform matcher only. A subscription to a whole data exchange (a data
  clean room) names a subscriber contact written by the subscriber in the
  request, so it is approved by the project that holds it instead: list
  those projects, by project ID, in
  `authorized_exchange_subscriber_project_ids`.
- **Bigquery.C111_C112** fails exchanges and listings with NO primary
  contact, by design.
- **Bigquery.C39_C40 (universal)** verifies the Omni-disable constraints on
  every project's effective policies: constraints inherited from the
  organization are visible on project payloads, so org-governed projects pass
  correctly and a project-level override fails. The Terraform matcher additionally flags declared weakening
  through both the current `google_org_policy_policy` and the legacy
  organization-policy resources: a constraint left unenforced, enforced only
  under a condition, or reset to its default (`spec.reset`, `restore_policy`).
  The allowlist mode reads the same policies and exempts only a policy set
  on an authorized Omni project. An Omni connection is approved only when it
  sets `project` to an authorized project.
- **Bigquery.C36_C37** checks two build-time surfaces: designated sensitive
  columns must be typed BYTES, the type that holds AEAD ciphertext, in
  declared table schemas, and declared queries naming sensitive tables must
  call the AEAD function family (`AEAD.ENCRYPT`, `DETERMINISTIC_ENCRYPT`).
  The type does not prove the values are encrypted, and the query text is
  not parsed, so the function name anywhere in the query passes. Queries
  reaching data through views or dynamic SQL are outside text-matching reach.
- **Bigquery.C4_C5** checks that each dataset carries a label naming an
  approved backup schedule. A label does not prove a backup exists, ran or
  can be restored, and tables and models are not checked.
- **Bigquery.C20_C21** reads a DLP trigger's inspection rules. An inspection
  job reports what it finds and changes nothing, so the rule does not show
  that data was redacted, and a sensitive table with no trigger gets no
  finding.
- **Bigquery.C23_C24** compares Cloud Storage and other source URIs, and the
  tables a load, extract, copy or query job reads or writes. A table list
  entry that names a dataset approves every table in it. Listings,
  connections and models are not read, and the tables a query reads in its
  SQL are not checked.
- **Bigquery.C27_C29** matches a key on project, location, key ring and key
  name together. BigQuery names a key, never a key version, so list keys
  without a version. In Terraform a table with no key of its own inherits
  the default key of its dataset when that dataset is in the same scan.
- **Bigquery.C76_C77** reads a job's write mode, create mode and schema
  update options.
  It does not read the query text, so `DROP`, `DELETE` and `TRUNCATE`
  statements are not detected.
- **Linked and external datasets** are read-only, so Bigquery.C18_C19,
  C27_C29 and C51_C52 skip them. Linked datasets are skipped by both
  matchers, external datasets by the Terraform matcher only. Access rules
  still check them.
- **Bigquery.C33_C34**: a Terraform table with no expiration of its own
  passes when its dataset, tied to it in the same scan, sets a default
  table expiration.
- **Bigquery.C128_C129** skips a project whose list of enabled services
  was not collected, so a missing list is never read as "disabled".
- **Bigquery.C99_C100**: a listing that leaves out `discovery_type` takes
  it from its exchange, and a restricted listing cannot set its own. An
  exchange that no scanned file declares cannot be read, so list it in
  `authorized_private_exchange_names_by_project_id` when it is private;
  otherwise the listing is reported. The cloud matcher needs no such list:
  a deployed listing always reports the discovery type in effect. It names
  an exportable listing by full name (`authorized_exportable_listing_names`,
  with the project number).
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

# threatmodel_compiler

Compiles `threatmodel-gcp-bigquery.json` — already the source of truth for this
repository's prevention controls — into multi-target detection content. The
compiler treats the JSON as a first-class **intermediate representation (IR)**
and emits, for each modeled threat:

| Target | Output |
|---|---|
| BigQuery (native) | `detect_<id>.sql` scheduled query + Terraform module |
| Chronicle | `detect_<id>.yaral` (YARA-L 2.0) |
| Splunk | `detect_<id>.spl` |
| Microsoft Sentinel | `detect_<id>.kql` |
| MITRE ATT&CK Navigator | a single coverage-layer JSON across all threats |

A coverage matrix (`detections/README.md`) is rebuilt every run and shows
`prevent / existing-detect / compiled-detect` per threat side-by-side.

## Why this matters

The repo today ships **prevention** (Wiz Rego, GCP custom org constraints) and
**documentation** (docx/pdf/drawio). Nothing programmatically consumes the
JSON, and the right-hand side of the kill chain — *detect* — is missing for
behavioral signals (the existing `Detect`-class controls are still Rego
config-posture, not audit-log behavior).

This compiler closes the loop. New threats added to the JSON automatically
yield detection content, ATT&CK coverage, and Terraform plumbing on the next
release tag — zero new content burden on maintainers.

## Quickstart

```bash
PYTHONPATH=tools python -m threatmodel_compiler --repo-root . compile \
  --threats T1 T6 T9
```

By default the compiler emits for `T1`, `T6`, `T9` — three reference threats
chosen to cover the `hlgoal` axis:

| Threat | hlgoal | Tactic | Why it's interesting |
|---|---|---|---|
| **T1** Destruction (delete table/dataset) | DoS | TA0040 Impact | High-signal, simple admin-activity emitter |
| **T6** Exfiltration (export to GCS/DLP) | DataTheft | TA0010 Exfiltration | Job-config inspection, allowlist regex |
| **T9** Unauthorized query (`SELECT *` / metadata abuse) | DataTheft | TA0010 | Query-pattern detection inside BigQuery's own audit logs |

T9 is the flagship example — BigQuery defending itself with the same product
the threat model covers.

## Repo layout the compiler produces

```
detections/
├── README.md                                     # coverage matrix
├── attack_navigator/
│   └── bigquery_threat_coverage.json             # ATT&CK Navigator layer
└── Bigquery.T<N>/
    ├── metadata.json                             # IR metadata + emitted artifacts
    ├── bigquery_sql/
    │   ├── detect_t<n>.sql
    │   └── terraform/main.tf
    ├── chronicle_yaral/detect_t<n>.yaral
    ├── splunk_spl/detect_t<n>.spl
    └── sentinel_kql/detect_t<n>.kql
```

## How the IR is consumed

1. **`loader.load(path)`** parses the JSON, drops retired entries, and
   *flattens* the AND/OR/OPTIONAL boolean access tree into
   `required_permissions` + `optional_permissions`. This is the key
   normalization that lets emitters reason about a threat without re-walking
   the tree.
2. **`permission_map.yaml`** maps each GCP IAM permission to the audit-log
   shape that emits on it (`service_name`, `method_names`, `log_type`). The
   compiler refuses to emit for a threat whose permissions are not all mapped
   — expanding coverage is then a focused PR adding entries here.
3. **Emitters** consume `(threat, signals)` and return strings. Each emitter
   owns its target dialect. Adding a new SIEM (e.g. Elastic, Sumo) is one new
   file in `emitters/`.

## Adding a threat

1. Confirm every permission referenced by the threat's `access` tree exists in
   `permission_map.yaml`. Add entries if not.
2. Add a per-threat detection template to each emitter
   (`bigquery_sql.py`, `chronicle_yaral.py`, etc.).
   Templates are explicit by design — this is detection-engineering content,
   not algorithmic rule generation.
3. Run `PYTHONPATH=tools python -m threatmodel_compiler compile --threats T<N>`.
4. Run `PYTHONPATH=tools python -m pytest tools/threatmodel_compiler/tests`.
5. Commit the new templates + the regenerated `detections/` tree. CI fails the
   PR if `detections/` drifts from the freshly compiled output.

## Validation

The pytest suite runs entirely offline:

* IR loads, access-tree flattens correctly for AND / OR / OPTIONAL.
* Every emitter produces non-empty content for the seeded reference threats.
* BigQuery SQL parses through `sqlglot` (BigQuery dialect).
* KQL passes structural sanity checks (balanced parens / brackets).
* YARA-L rules contain `meta:`, `events:`, `condition:` sections.
* MITRE technique IDs resolve and the ATT&CK Navigator layer is well-formed.
* Terraform module passes `terraform validate` (skipped if binary missing).
* Compiled SQL contains no destructive statements (no `DROP`/`DELETE`/`UPDATE`/
  `GRANT`/`REVOKE` outside string literals).

Optional vendor validators (`gcloud chronicle rules validate`, Splunk
`btool`) are gated and not part of the default CI matrix.

## Non-goals

* Not a runtime detection engine. The compiler emits artifacts; deployment is
  out of scope and intentionally left to the user's existing detection-as-code
  workflow.
* Not an attempt to enumerate every BigQuery threat. Three reference threats
  are wired end-to-end. The pattern is the deliverable; the long tail is a
  follow-up PR per threat.
* Not a generic threat-model compiler. Tightly coupled to the
  `threatmodel-gcp-bigquery.json` schema. Generalizing across services is a
  v2 conversation.

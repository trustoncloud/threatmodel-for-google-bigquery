## Intro

Sigma is a portable detection rule format for log and SIEM use, similar in spirit to how YARA describes patterns for files. It lets security teams write one rule in a simple, readable format and then convert or translate it into queries for different SIEMs and log platforms.

It's especially useful for sharing detections across teams and tools without rewriting the logic every time. In practice, Sigma helps analysts express "what to look for" in logs, while the SIEM-specific backend handles how to query that data.

To learn more about Sigma, check their official documentation: https://sigmahq.io

As Sigma is focused on detection rules for logs, the scope is the Detective/Detect controls, as these controls monitor for a specific indicator of compromise (e.g., a logging event with specific parameters).

In this directory you can find the sigma rules and variables for the rules. Variables in Sigma are named placeholders embedded directly in a rule's detection logic, written as `%variable_name%` and resolved at query-generation time through a transformation file. It allows you to write a single rule and during query generation, you can fill up these placeholders with environment-specific values, that match your needs without rewriting the rule logic itself.

## Rule modes

The Sigma rules use the same approach as the Open-source WIZ-CCR we published. Each control can be translated to up to 3 rule modes, depending on how the detection logic is defined or tuned.

**Universal mode:** where the log pattern provides all information needed without any customer-supplied input. It is used when a rule should apply with no exceptions.

**Allowlist mode:** need customer input via variables. The detection works for all the events that are not related to a resource that the customer marked as authorized, which can be a BigQuery reservation, a service account, a dataset, or anything else mentioned in our controls. Customers fill up the variable file with their custom values for authorized resources, and during conversion, the query generated checks for events related only to resources not listed as authorized.

**Denylist mode:** opposite behavior from the allowlist. It needs customer input via variables, but in this mode the customer provides unauthorized resources as values, setting the scope to specific bad values. Useful when only a small portion of resources are considered a violation, and anything else is acceptable.

Important to note that not every control needs all 3 modes, and in fact very few implement all 3 modes. Some detections are unambiguous enough that only the universal variant makes sense, while others are context-dependent and only the allowlist or denylist variant is practical.

## Rule levels

The [Sigma documentation](https://sigmahq.io/docs/basics/rules.html#metadata-level) defines five level values: critical, high, medium, low and informational.

TrustOnCloud threatmodels use a five-step scale that almost matches Sigma. As of now we are using the following mapping between TrustOnCloud control and Sigma rules:

|TrustOnCloud |	Sigma level |
|---|---|
|Very High	| critical |
|High	| high |
|Medium	| medium |
|Low	| low |
|Very Low |	informational |

## Variables

This folder holds the **per-customer settings** the Sigma rules read at conversion time — *"these are the reservation configurations my org has approved"*, *"these service accounts are authorized to manage data transfers"*. The rules stay generic and reusable; while your environment-specific values live here.

Each variable name carries the **control ID it belongs to** as a suffix, so it's obvious which rule a value affects.

| File | What it contains |
|---|---|
| `customer.gcp.bigquery.example.yml` | Sample GCP BigQuery profile — placeholder reservations, project paths, service accounts, dataset IDs, Pub/Sub topics |

### How to use the variables

1 - Edit or copy the variable files, replacing each placeholder with your real reservation names, project paths, service accounts, dataset IDs, etc. Inline comments explain what each variable controls and which rule uses it.

2 - Run a sigma parser (e.g., [sigma-cli](https://github.com/SigmaHQ/sigma-cli), [RSigma](https://github.com/timescale/rsigma), [PySigma](https://github.com/SigmaHQ/pySigma)) with your variable file

3 - The generated SIEM queries contain your real values, to be used with your playbooks, SIEM, SOC, etc.

## Summary of GCP BigQuery controls and Sigma rules

| **#** | **Control** | **Control Definition** | **Control Testing** | **Sigma Rule Summary** | **Rule Level** | **Allowlist Mode** | **Denylist Mode** | **Universal Mode** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | C63 | Monitor the creation/modification of unauthorized reservations (e.g., by using Cloud Logging event `google.cloud.bigquery.reservation.v1.ReservationService.CreateReservation` and `google.cloud.bigquery.reservation.v1.ReservationService.UpdateReservation`, and their fields `request.reservation.autoscale.maxSlots` and `request.reservation.edition`). | Create/update the reservation with unauthorized values; it should be detected. | Detects CreateReservation and UpdateReservation events where the `maxSlots` or `edition` value is not in the customer's authorized allowlist. | Medium | Yes | N/A | N/A |
| 2 | C64 | Monitor the creation/modification of unauthorized assignments (e.g., by using Cloud Logging event `google.cloud.bigquery.reservation.v1.ReservationService.CreateAssignment` and its fields `request.assignment.assignee`, `request.assignment.jobType`, and `request.parent`, and event `google.cloud.bigquery.reservation.v1.ReservationService.UpdateAssignment` and its fields `request.assignment.assignee` and `request.assignment.jobType`). | Create/update the assignment with unauthorized values; it should be detected. | Detects CreateAssignment and UpdateAssignment events where the assignee resource path or parent prefix is not in the customer's authorized allowlist. | Medium | Yes | N/A | N/A |
| 3 | C88 | Monitor the creation/modification of unauthorized data transfers (e.g., by using Cloud Logging events `google.cloud.bigquery.datatransfer.v1.DataTransferService.CreateTransferConfig` and `google.cloud.bigquery.datatransfer.v1.DataTransferService.UpdateTransferConfig` and their fields `request.serviceAccountName`, `request.transferConfig.dataSourceId`, `request.transferConfig.destinationDatasetId`, `request.transferConfig.notificationPubsubTopic`, and `request.transferConfig.schedule`). | Create/update an unauthorized data transfer; it should be detected. | Detects CreateTransferConfig and UpdateTransferConfig events where the data source ID, destination dataset, service account, Pub/Sub topic, or schedule is not in the customer's authorized allowlists. | Medium | Yes | N/A | N/A |
| 4 | C132 | Monitor the failover mode of a reservation (e.g., by using Cloud Logging event `google.cloud.bigquery.reservation.v1.ReservationService.FailoverReservation` and its field `request.failoverMode`). | Fail over a reservation in hard mode; it should be detected. | Detects FailoverReservation events in HARD mode where the calling principal or reservation path prefix is not in the customer's authorized allowlist. | Informational | Yes | N/A | N/A |

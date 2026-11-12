# Remediation

The subscription in the finding is to a listing or data exchange that is not an authorized source, or it sits in a project, or links a dataset into a project, that is not approved to subscribe. Either end the subscription, or authorize the source or the project.

To end it, delete the subscription. No gcloud or bq command manages BigQuery sharing subscriptions, so use the Analytics Hub API's `projects.locations.subscriptions.delete` method. For a subscription to a BigQuery dataset listing, deleting its linked dataset also ends it.

```bash
curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://analyticshub.googleapis.com/v1/projects/<project-id>/locations/<location>/subscriptions/<subscription-id>"
```

The publisher of the listing can end it from their side with `projects.locations.subscriptions.revoke`. A cancelled or revoked subscription is not reported.

If the source is approved, add its full name as the finding shows it, with the publisher's project number, to the rule's configuration: an exchange to `authorized_source_exchange_names`, which approves every listing in it, or a single listing to `authorized_source_listing_names`. If the project is approved to subscribe, add its project ID to `authorized_subscriber_project_ids`, or, when the finding names only the linked dataset, its project number to `authorized_subscriber_project_numbers`. The rule for linked datasets of this control carries the same lists in its own copy of the configuration, so set them there too. A subscription belongs to the subscriber's project, so a subscription held in a project that is not scanned does not appear, and subscriptions in multi-region locations may not be among those scanned. Replace `<project-id>`, `<location>` and `<subscription-id>` with the subscription named in the finding.

## References

- [Manage subscriptions](https://docs.cloud.google.com/bigquery/docs/analytics-hub-manage-subscriptions)
- [View and subscribe to listings and data exchanges](https://docs.cloud.google.com/bigquery/docs/analytics-hub-view-subscribe-listings)

Checked 2026-11-11: all links above resolve.

## Testing Compliance
1) Subscribe to an unauthorized listing and/or data exchange with an entity you control, or 2) subscribe with an unauthorized entity you control to a listing or exchange authorized for other entities you control; it should be detected.

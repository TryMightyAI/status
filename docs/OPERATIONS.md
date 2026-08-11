# Incident and maintenance runbook

This runbook governs the **public status timeline**. Mighty’s private incident
response, security, legal, customer-notification, and recovery procedures remain
authoritative.

## What belongs on the page

Publish a status incident when a confirmed production problem materially
prevents or degrades customer use of a listed component. Publish scheduled
maintenance when an upcoming deployment or infrastructure change could create
customer impact.

Do not publish every normal code push. Use a product changelog for ordinary
releases. The status page is for availability and customer-impacting work.

Never include customer names/data, credentials, internal addresses, unpatched
exploit details, speculation, or statements that legal/security responders have
not authorized. A public status post never replaces contractual, regulatory,
or direct affected-customer notice.

## Automated incidents

Upptime opens an Issue when a check fails and closes it after recovery. The
assigned incident publisher should:

1. Correlate the alert with internal monitoring before describing scope.
2. Rename the Issue to a clear customer-facing summary if needed.
3. Add a new comment for each stage; do not silently rewrite the timeline:
   - **Investigating** — observed impact and known scope;
   - **Identified** — cause category and mitigation, without risky detail;
   - **Monitoring** — service restored and validation in progress;
   - **Resolved** — validated resolution and final customer impact; and
   - **Post-incident note** — link or safe summary when appropriate.
4. State the next update time or cadence in the first confirmed public update,
   then meet it or explicitly correct it. Do not invent an ETA.
5. If an earlier statement is wrong, add a correction comment that preserves
   what changed and when.
6. Reconcile the public timestamps with the private incident record after
   resolution.

`skipDeleteIssues: true` preserves short and false-positive incidents. Explain a
false positive in a closing comment; do not delete it to make the record look
cleaner.

## Scheduled maintenance and customer-impacting pushes

1. Open a **Scheduled maintenance** Issue early enough for the approved notice
   target.
2. Replace every placeholder in the hidden metadata with ISO 8601 UTC times.
3. List only affected slugs: `website`, `api`, `scan-gateway`.
4. Describe expected customer impact, purpose at a safe level, rollback owner,
   and where updates will appear.
5. Use `expectedDown` only for an expected outage and `expectedDegraded` only for
   expected degraded service. These fields suppress automatic incident noise;
   they must not hide unplanned impact.
6. Comment when work starts, if scope/timing changes, and when validation ends.
7. If actual impact exceeds the notice, treat it as an incident and preserve the
   full timeline.

## Evidence and retention

For each incident or maintenance selected for audit, retain or export:

- alert/check records and relevant internal monitor evidence;
- Issue body, comments, labels, authors, edits, and timestamps;
- severity/owner decisions and private response timeline;
- direct subscriber/customer notices when applicable;
- resolution validation, post-incident review, and corrective actions; and
- the configuration/deployment pull request for planned work.

Git and GitHub Issues are supporting evidence, not the only system of record.
Retain exports for the full Type 2 observation period and the organization’s
approved policy/legal period. Block force-push and deletion where practical.

## Accuracy and uptime language

The page reports samples from external checkers. GitHub scheduled jobs may be
delayed, and a green check does not prove every feature or region works. Do not
call the displayed percentage an SLA, guarantee, or contractual availability
calculation unless the governing contract and measurement method explicitly do
so.

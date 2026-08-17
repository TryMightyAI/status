---
name: Scheduled maintenance
about: Announce customer-impacting maintenance or a risky production push
title: "[Scheduled Maintenance] "
labels: maintenance
assignees: ""
---

> **Required:** Replace both 2000 timestamps with the approved UTC start/end.
> Add `expectedDown` or `expectedDegraded` inside the metadata comment only
> when that impact is expected. Never leave either key with an empty value;
> the pinned monitor cannot parse an empty `key:` line.

<!--
start: 2000-01-01T00:00:00Z
end: 2000-01-01T00:30:00Z
-->

Valid component slugs: `website`, `api`, `scan-gateway`.
Optional metadata examples: `expectedDown: api` and
`expectedDegraded: website, scan-gateway`.

## Summary

What work is happening, and why is a public notice appropriate?

## Expected customer impact

Describe affected capabilities, regions if relevant, and whether interruption
or degraded performance is expected. Do not include sensitive implementation
details.

## Update plan

State where and when the next update will appear.

## Operator checklist

- [ ] Approved start/end times are in UTC and replace the 2000 placeholders.
- [ ] Affected component slugs are accurate.
- [ ] Change/rollback owner and approval exist in the private change record.
- [ ] Security/privacy/legal review is complete if the notice needs it.

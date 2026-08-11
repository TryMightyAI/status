# Status page platform decision

**Decision date:** 2026-08-11
**Decision:** Upptime in a dedicated public repository, with the generated site
served from Cloudflare Pages at `status.trymighty.ai`.

## Requirements

The selected system must be open source, inexpensive to operate, outside the
Mighty production stack, usable at a custom domain, and able to show current
checks, incident updates, scheduled work, and past events. Its records should
support a SOC 2 Type 2 examination without being represented as compliance by
themselves.

## Shortlist

| Project | Strengths | Important limits | Result |
| --- | --- | --- | --- |
| [Upptime](https://github.com/upptime/upptime) | MIT; static site; free public-repo checks; incidents and operator comments use GitHub Issues; scheduled maintenance; Git history; custom domain | GitHub cron can be delayed; five-minute minimum; requires a narrowly scoped write token; public GitHub/API dependency | **Selected: best match for zero-cost static hosting plus durable commentary** |
| [UptimeFlare](https://github.com/lyc8503/UptimeFlare) | Apache-2.0; Cloudflare Workers/Pages; one-minute and geographic checks; maintenance and automatic incident history | No comparable threaded human incident-update workflow; 90-day monitoring history; fixed 2026 credential-exposure advisory requires careful upgrades | Best free monitoring architecture, but not the best incident-communications record |
| [cState](https://github.com/cstate/cstate) | MIT; very small Hugo static site; excellent Git-authored incident posts | Explicitly has no automatic monitoring out of the box | Good manual communications site, incomplete alone |
| [Gatus](https://github.com/TwiN/gatus) | Apache-2.0; small Go service; broad checks; Markdown announcements and archived history | Always-on service and storage; no threaded incident workflow or subscriber system | Strong small self-hosted alternative, not static |
| [Kener](https://github.com/rajnandan1/kener) | MIT; full incident timelines, maintenance, roles, API, and notifications | Requires an always-on Node/Redis/database service and its own backup/security operations | Best lightweight GUI if static hosting stops being a requirement |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | MIT; mature monitor and public pages; maintenance support | Stateful single service; human updates are more mutable and less audit-friendly | Good monitor, weaker fit for controlled public communications |
| [OpenStatus](https://github.com/openstatusHQ/openstatus) | AGPL-3.0; polished monitoring, incident reports, maintenance, subscribers | Managed custom domains are paid; self-hosting is a multi-service stack | Strong managed option, not the requested free/static setup |
| [OneUptime](https://github.com/OneUptime/oneuptime) | Apache-2.0; complete managed monitoring/incident platform; vendor advertises SOC 2 Type II | Active managed monitors are not fully free; self-hosting is far too heavy for one status page | Revisit if subscribers, a vendor SLA, or a full incident platform justify cost |
| [Cachet 3.x](https://github.com/cachethq/cachet) | Rich incident and schedule UI | Current custom license restricts standalone redistribution and is not an OSI-approved open-source license; dynamic PHP/DB stack | Rejected |
| [Statusfy](https://github.com/juliomrqz/statusfy) | Static Markdown incidents | Archived and explicitly unmaintained | Rejected |

Repository activity, releases, licenses, documentation, and security advisories
were checked from official project sources on the decision date.

## Why Upptime

Upptime maps the public operating workflow onto tools Mighty already reviews:

- Actions make external HTTP checks.
- A failure opens an Issue.
- Operators add timestamped comments such as investigating, identified,
  monitoring, and resolved updates.
- Maintenance is an Issue with explicit UTC start/end metadata.
- Git stores check history and reviewed configuration.
- A static site is generated onto `gh-pages` and can be served by Cloudflare
  Pages without an application server or database.

This repository deliberately changes two upstream defaults. Short incidents are
**not deleted** (`skipDeleteIssues: true`), and self-updating workflows are
removed. Those choices retain evidence and require supply-chain changes to go
through review.

## Hosting decision

Cloudflare Pages should serve the already-generated `gh-pages` branch. It gives
Mighty a static global edge site and managed TLS outside the GCP production
stack. Use the Cloudflare Git integration restricted to this public repository;
do not put a broad Cloudflare API token in GitHub Actions. GitHub Pages is an
acceptable fallback host if the Pages integration cannot be approved.

The public GitHub Issues list is the alternate communications URL if the custom
domain or Cloudflare is unavailable. This is not complete independence—Upptime
still uses GitHub for checks and incident data—so Mighty’s existing internal
monitoring remains the source for paging and audit evidence. The page is a
communication layer and an independent secondary observation.

## SOC 2 interpretation

SOC 2 does not require a public status page and the page does not make Mighty
compliant. It can support:

- AICPA Trust Services Criteria CC2.3 (relevant, timely external communication),
  CC7.4/CC7.5 (appropriate incident and recovery communication), CC8.1
  (controlled changes), and A1.2/A1.3 (recovery capability and testing).
- A Type 2 examination’s need to show that described controls operated during
  the review period.

The internal incident record must still reconcile monitoring alerts, tickets,
communications, recovery, and corrective work. Public text must not disclose
customer data or exploitable security details. Published uptime is an observed
measurement, not an SLA unless a contract explicitly says otherwise.

Authoritative references:

- [AICPA 2017 Trust Services Criteria, revised points of focus 2022](https://www.aicpa-cima.com/resources/download/2017-trust-services-criteria-with-revised-points-of-focus-2022)
- [AICPA 2018 SOC 2 Description Criteria, revised implementation guidance 2022 (PDF)](https://assets.ctfassets.net/rb9cdnjh59cm/1vCduR1U2OnhIvFFaDBjMv/836050054707e9afb65adeb30d2e95d8/92317096_dc_section_200_clean_version.pdf)
- [NIST SP 800-61 Rev. 3 incident-response recommendations (PDF)](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r3.pdf)
- [Upptime scheduled maintenance](https://upptime.js.org/docs/scheduled-maintenance/)
- [Upptime scheduler limitation](https://upptime.js.org/blog/2021/01/22/github-actions-schedule-not-working/)

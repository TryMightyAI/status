# Hosting and launch checklist

## Recommended topology

```text
GitHub Actions (secondary public checks)
        │
        ├── main: config, history, incident Issues/comments
        └── gh-pages: generated static website
                           │
                           ▼
                 Cloudflare Pages + TLS
                           │
                    status.trymighty.ai

Mighty internal monitoring ──> paging/private incident record/audit evidence
```

The status system must stay outside the Mighty GCP application stack. A failure
of the web app, API, gateway, cluster, or product deployment pipeline must not
prevent the static page from loading.

## Before enabling automation

Every production job has a checked-in launch gate:
`vars.STATUS_AUTOMATION_ENABLED == 'true'`. The variable must remain absent or
false while the launch pull request is under review. The read-only `Validate`
workflow may run on the pull request; it builds but never publishes the site.

1. Confirm `STATUS_AUTOMATION_ENABLED` is absent/false, then review and merge the
   launch pull request. Scheduled jobs will skip safely while the gate is off.
2. Prefer a dedicated bot/machine user protected with MFA. Create a
   **fine-grained, expiring** GitHub token limited to `TryMightyAI/status` with
   read/write access to Contents and Issues only (Metadata read is implicit).
   The hardened workflows do not need Actions or Workflows write access.
   Upptime calls this secret `GH_PAT`.
3. Store it as the repository Actions secret `GH_PAT`. Record the owner,
   approval, expiry, and rotation date in Mighty’s approved credential register;
   do not put the token in an Issue, commit, or Cloudflare variable.
4. Keep the repository's default `GITHUB_TOKEN` permission read-only and keep
   “Allow GitHub Actions to create and approve pull requests” disabled. Keep the
   Actions allowlist limited to GitHub-owned actions plus the two exact
   commit-SHA patterns recorded in the workflows; never switch it to “allow all.”
5. Verify GitHub private vulnerability reporting is enabled and the private
   advisory URL works for a non-admin reporter.
6. Create the `maintenance` label if it does not exist.
7. Run `Validate`. Only after the secret, label, and security checks pass,
   enable the three production workflows and set the repository variable
   `STATUS_AUTOMATION_ENABLED` to exactly `true`.
8. Manually trigger these workflows in order: `Uptime CI`, `Response Time CI`,
   and `Static Site CI`. To pause safely, set the variable to `false` before
   rotating the token or changing automation.
9. Confirm that `history/` and the `gh-pages` branch contain only Mighty data.
   Never import the upstream demo measurements.

## Cloudflare Pages (recommended)

Wait until `Static Site CI` creates `gh-pages`, then:

1. In Cloudflare Pages, connect the public `TryMightyAI/status` repository.
2. Select `gh-pages` as the production branch.
3. Use no framework preset, no build command, and `.` as the output directory;
   the branch already contains generated static files.
4. Expose no build secrets. Restrict the Cloudflare GitHub integration to this
   repository rather than reusing a broad application API token.
5. Attach the custom domain `status.trymighty.ai`. When the zone is in the same
   Cloudflare account, let Pages create the required DNS record and certificate.
6. Leave Cloudflare Access/password protection **off** for the public page.
7. Keep the default `*.pages.dev` hostname enabled as an operator diagnostic URL,
   but publish the GitHub Issues list as the Cloudflare-independent fallback.

Cloudflare must deploy after every force/update to `gh-pages`. Validate this with
a harmless branding pull request before launch. The static shell is rebuilt for
configuration/branding changes, but live component status, incident comments,
and scheduled maintenance are fetched from GitHub at page load; an outage update
does not wait for a Cloudflare rebuild.

## GitHub Pages alternative

If Cloudflare Pages cannot be approved, publish `gh-pages` `/ (root)` with
GitHub Pages and configure `status.trymighty.ai` as the custom domain. Do not run
both providers for the same custom hostname. The public repository and Issues
remain the alternate channel.

## Launch validation

From at least two networks/regions:

```sh
curl --fail --show-error --location https://status.trymighty.ai/
curl --fail --show-error https://trymighty.ai/
curl --fail --show-error https://api.trymighty.ai/health
curl --fail --show-error https://gateway.trymighty.ai/health
```

Also verify:

- valid TLS, automatic HTTP-to-HTTPS redirect, and the security headers from `assets/_headers`;
- logo, CSS, component history, and incident links;
- a future UTC maintenance test appears before its start, then moves into past
  history after closing/completion;
- a repository admin can post an update when the Mighty application and normal
  identity path are assumed unavailable;
- Cloudflare redeploys an updated `gh-pages` commit;
- the GitHub Issues fallback is documented in the internal incident runbook;
- private vulnerability reporting works without public disclosure;
- an external monitor checks the public status page without depending on this
  repository's scheduler or Cloudflare Pages; and
- launch screenshots, headers, workflow run URLs, DNS/TLS result, and test Issue
  export are saved to the approved evidence store.

Do not claim the status-page control is operating until this test is complete.

## Ongoing hosting controls

- Monitor the status page itself from a service that does not depend on
  Cloudflare Pages or this repository's scheduler.
- Review repository access and the bot token at the organization’s approved
  cadence; remove leavers promptly and rotate before token expiry.
- Review Cloudflare Pages project access and deployment history.
- Export the repository and Issue/comment audit population for each SOC 2
  review period. A screenshot alone is weak evidence.
- Test the alternate publishing path at least annually and after material
  provider/DNS/identity changes.
- Apply upstream security updates through the reviewed process in `UPSTREAM.md`.

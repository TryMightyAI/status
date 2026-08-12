# Hosting and launch checklist

## Recommended topology

```text
GitHub Actions (secondary public checks)
        │
        ├── main: config, history, incident Issues/comments
        └── gh-pages: generated static website
                           │
                           ▼
             GitHub Pages + GitHub TLS
                           │
               Cloudflare DNS-only CNAME
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

Production does **not** need a stored personal access token. Each enabled job
requests only the short-lived repository token permissions it needs: Contents
and Issues write for monitoring, or Contents write for static publication.
GitHub expires that token after the job. Commits made with it intentionally do
not chain into other workflows; live status and Issues are read at page load,
and the static shell has its own schedule.

1. Confirm `STATUS_AUTOMATION_ENABLED` is absent/false, then review and merge the
   launch pull request. Scheduled jobs will skip safely while the gate is off.
2. Keep the repository's default `GITHUB_TOKEN` permission read-only and keep
   “Allow GitHub Actions to create and approve pull requests” disabled. Do not
   add a `GH_PAT` secret.
3. Keep the Actions allowlist limited to GitHub-owned actions plus the two exact
   commit-SHA patterns recorded in the workflows; never switch it to “allow all.”
4. Verify GitHub private vulnerability reporting is enabled and the private
   advisory URL works for a non-admin reporter.
5. Create the `maintenance` label if it does not exist.
6. Run `Validate`. Only after the label and security checks pass, enable the
   three production workflows and set the repository variable
   `STATUS_AUTOMATION_ENABLED` to exactly `true`.
7. Manually trigger these workflows in order: `Uptime CI`, `Response Time CI`,
   and `Static Site CI`. To pause safely, set the variable to `false` before
   changing automation.
8. Confirm that `history/` and the `gh-pages` branch contain only Mighty data.
   Never import the upstream demo measurements.

## Production hosting: GitHub Pages with Cloudflare DNS

`Static Site CI` publishes the generated site from `gh-pages`. GitHub Pages
serves that branch, owns the certificate, and redirects HTTP to HTTPS. Cloudflare
is DNS-only: `status.trymighty.ai` is a CNAME to `trymightyai.github.io` and is
not proxied through Cloudflare.

In repository Pages settings, keep the source set to the `gh-pages` branch at
`/ (root)`, preserve the custom domain `status.trymighty.ai`, and keep HTTPS
enforcement enabled. Do not enable Cloudflare Pages, Workers, or proxying for the
same hostname without a reviewed hosting migration.

GitHub Pages does not apply the Cloudflare-style rules in `assets/_headers`.
Those rules remain a reviewed baseline for a future hosting layer, not evidence
of live response headers. The public repository and Issues are the independent
fallback if the custom hostname or static page is unavailable.

## Launch validation

From at least two networks/regions:

```sh
curl --fail --show-error --location https://status.trymighty.ai/
curl --fail --show-error https://trymighty.ai/
curl --fail --show-error https://api.trymighty.ai/health
curl --fail --show-error https://gateway.trymighty.ai/health
```

Also verify:

- valid TLS and automatic HTTP-to-HTTPS redirect; treat `assets/_headers` as an unapplied baseline while GitHub Pages remains the host;
- logo, CSS, component history, and incident links;
- a future UTC maintenance test appears before its start, then moves into past
  history after closing/completion;
- a repository admin can post an update when the Mighty application and normal
  identity path are assumed unavailable;
- GitHub Pages deploys the updated `gh-pages` commit;
- the GitHub Issues fallback is documented in the internal incident runbook;
- private vulnerability reporting works without public disclosure;
- an external monitor checks the public status page without depending on this
  repository's scheduler or GitHub Pages; and
- launch screenshots, response headers, workflow run URLs, DNS/TLS result, and
  test Issue export are saved to the approved evidence store.

Do not claim the status-page control is operating until this test is complete.

## Ongoing hosting controls

- Monitor the status page itself from a service that does not depend on GitHub
  Pages or this repository's scheduler.
- Review repository access and workflow job permissions at the organization’s
  approved cadence; remove leavers promptly.
- Review GitHub Pages settings and deployment history.
- Export the repository and Issue/comment audit population for each SOC 2
  review period. A screenshot alone is weak evidence.
- Test the alternate publishing path at least annually and after material
  provider/DNS/identity changes.
- Apply upstream security updates through the reviewed process in `UPSTREAM.md`.

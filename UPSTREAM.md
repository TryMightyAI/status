# Upstream and supply-chain policy

This repository was created from the public [Upptime template](https://github.com/upptime/upptime)
on 2026-08-11.

- Template commit: [`8a77a68e276fd9ecae0aaa64bfaf4b987e5ca7bb`](https://github.com/upptime/upptime/commit/8a77a68e276fd9ecae0aaa64bfaf4b987e5ca7bb)
- Template tree: `227dccfa97ac3fc6b42d85ebd2cb0dc32ae1aab8` (verified identical to this repository's initial commit)
- Runtime release: [`upptime/uptime-monitor@v1.43.13`](https://github.com/upptime/uptime-monitor/releases/tag/v1.43.13)
- Runtime commit: [`4fec88256b5917a2ed07a088df6e205869b424d6`](https://github.com/upptime/uptime-monitor/commit/4fec88256b5917a2ed07a088df6e205869b424d6)
- Static-site release: [`upptime/status-page@v1.17.0`](https://github.com/upptime/status-page/releases/tag/v1.17.0)
- Static-site commit: [`54c2ff5a3d998d525ee4c7e68dc7ce7414d89c33`](https://github.com/upptime/status-page/commit/54c2ff5a3d998d525ee4c7e68dc7ce7414d89c33)
- License: [MIT](LICENSE)

## Why automatic template updates are disabled

The upstream template normally runs code from moving tags/branches and rewrites
its own workflows. That is convenient, but it bypasses review and weakens the
status page's integrity. Mighty instead:

1. pins every GitHub Action and the static-site source to full commit SHAs;
2. builds the site with the upstream release's committed `package-lock.json`;
3. patches the old static client to read Mighty’s `main` branch and removes its
   optional pre-rendered PNG graph dependency (history charts still render from
   Git commits in the browser);
4. passes no monitor credentials (`secrets: []`) and stores no long-lived
   automation token;
5. uses GitHub’s short-lived job token with only Contents/Issues write for the
   monitor and Contents write for static publication;
6. reviews upstream changes in a pull request; and
7. runs `ruby scripts/validate.rb` plus a no-publish static build before merging.

## Upgrade procedure

At least monthly, and promptly after an upstream security advisory:

1. compare the current template, monitor runtime, and status-page release with the SHAs above;
2. review source changes, release notes, dependencies, and open advisories;
3. regenerate only the required Upptime files on a branch;
4. restore full-SHA pins and least-privilege workflow settings;
5. run the validator and a test deployment;
6. merge through normal review; and
7. update the SHAs and date in this file.

Do **not** run Upptime's `update-template` command directly on `main`.

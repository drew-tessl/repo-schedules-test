# repo-schedules-test

A scratch repo for testing **repo-defined schedules**: schedules declared in
`tessl.json` and reconciled by Tessl on push, instead of created through
`tessl schedule create` or the web app.

## How it works

On a push to this repo's default branch, the Tessl **Sync** GitHub App webhook
reads `tessl.json`, validates its `schedules` block, and creates, updates, or
deletes `repo`-type schedules to match. The file is the source of truth:

- Add an entry → a schedule is created.
- Change an entry → the schedule is updated in place.
- Remove an entry (or delete the file) → the schedule is deleted.
- Rename a key → delete + create. Keys are identities, not labels.

Repo-defined schedules are read-only through the API and the web app: `PATCH`
and `DELETE` are rejected, because the file owns them. `tessl schedule trigger`
still works, which is how you fire one out of band without waiting for its cron.

## The schedule in this repo

One entry, `launch-smoke-test`. It runs the repo-local plugin in
`plugins/launch-smoke-test/` (referenced by path as `file:`, not from the
registry), which reads one Linear issue, appends a timestamped marker line to
`SMOKE-LOG.md`, and opens a pull request with that one-line change. A PR
appearing here is unambiguous evidence the schedule fired and the sandbox got
its credentials.

## Prerequisites

| What | Why |
|---|---|
| Tessl **Sync** GitHub App installed on this repo | The Agent App's pushes are ignored for schedules |
| Schedules committed on the **default branch** | Pushes to other branches are ignored |
| A workspace environment named `drew-test-env` holding `GITHUB_TOKEN` (or `GH_TOKEN`) and `LINEAR_TOKEN` | A scheduled fire cannot mint its own GitHub token, so the environment is its only source. A token-less environment is skipped silently |
| `schedules-repo-flag` enabled | Off by default. The webhook is unauthenticated, so the flag evaluates against PostHog distinct id `unknown`, so a per-user enable has no effect |

An entry whose environment, skill ref, agent/model, or inputs do not validate is
**skipped**, not failed: the rest of the file still applies, and nothing is
deleted. Skips are logged server-side, which means a schedule that never appears is a
log-reading exercise rather than an error you will see in the UI.

## Schema

The `schedules` block is validated by `SchedulesConfigSchema` in
`@tileworks/m`. It is strict (an unknown field is an error, not ignored), keys
must be lowercase kebab-case, and a cron may not fire more often than every
5 minutes. `skill`, `cron`, and `environment` are required; `timezone`
(default UTC), `baseBranch` (default `main`), `snapshot`, `workdir`, `agent`,
`model`, `inputs`, `instructions`, and `description` are optional.

`environment` names an environment; it is not an id. Ids are workspace-scoped
and would resolve to nothing in a second workspace, so the file names the
environment and the apply step resolves it per workspace.

<!-- sync trigger -->

<!-- retry sync -->

<!-- post-EXP-10177 sync test -->

<!-- resync after tessl-side auth redo -->

<!-- resync after full auth redo -->

---
name: launch-smoke-test
description: >-
  End-to-end smoke test for the `tessl launch skill --cloud` pipeline. Reads one
  Linear issue (read-only) via the Linear API to prove `LINEAR_TOKEN` is wired
  into the sandbox, appends a single run-marker line to a log file, then opens a
  GitHub pull request with that one-line change to prove `GITHUB_TOKEN` and the
  publish path work. Use whenever you need to verify a cloud launch can reach
  Linear and GitHub and open a PR end to end -- dogfooding the launch pipeline,
  checking that credentials forward into the sandbox, or as a minimal known-good
  skill to launch when debugging the launch flow itself. Self-contained: driven
  by launcher-supplied inputs plus `LINEAR_TOKEN` and `gh` credentials in the
  environment. Makes no Linear writes; its only change is the one appended log
  line in the PR it opens.
schemas:
  output:
    $ref: ./schemas/output.schema.json
---

# Launch Smoke Test

A deliberately tiny launch skill whose only purpose is to prove the
`tessl launch skill --cloud` pipeline works end to end. It touches both external
systems a real launch skill depends on -- **Linear** (read) and **GitHub**
(write) -- with the smallest possible footprint, so a green run means the
sandbox got its credentials, can talk to both services, and can open a PR.

It does three things, and **only** these three:

1. **Reads** one Linear issue through the Linear API (read-only -- proves
   `LINEAR_TOKEN` is present and valid).
2. **Appends** a single run-marker line to a log file (the small change).
3. **Opens** a pull request containing that one-line change (proves `gh` /
   `GITHUB_TOKEN` and the publish path work).

It makes **no Linear writes** and produces **no other repo changes**. If you are
looking for a skill that does real work, this is not it -- this is the smoke
test you run to confirm the pipeline is healthy before trusting it with real
work.

---

## Inputs

The launcher supplies these via `.cloud-launch/inputs.json`. All are optional;
the defaults make the skill runnable with no inputs at all.

| Placeholder | Default | Description |
|---|---|---|
| `{{ISSUE_IDENTIFIER}}` | `AE-669` | The Linear issue to read. Any issue the token can see works; the default is a stable, completed issue. Only its `identifier` and `title` are read. |
| `{{LOG_FILE}}` | `SMOKE-LOG.md` | Repo-relative path of the file the run marker is appended to. Created if absent. |
| `{{BRANCH_PREFIX}}` | `launch-smoke-test` | Prefix for the branch the PR is opened from. |

The environment must carry:

- **`LINEAR_TOKEN`** -- a Linear API token authorised to read issues. Used only
  for the single read below.
- **GitHub credentials** -- `GH_TOKEN` / `GITHUB_TOKEN` so the `gh` CLI can push
  the branch and open the PR.

If either is absent, stop and report the missing credential rather than guessing
-- a missing credential is exactly the kind of pipeline break this skill exists
to surface.

---

## Procedure

You are running in a clone of the target repo, checked out on its base branch,
at the repository root. Git already has a credential helper and a bot commit
identity configured, so `git push` and `gh pr create` authenticate without any
setup -- do not reconfigure auth, and never print or commit the tokens.

### 1. Read the Linear issue

Fetch the issue named by `{{ISSUE_IDENTIFIER}}`. Linear's `issue(id:)` query
accepts the human identifier (e.g. `AE-669`) directly:

```bash
curl -s https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query($id: String!) { issue(id: $id) { identifier title url state { name } } }","variables":{"id":"{{ISSUE_IDENTIFIER}}"}}'
```

Keep the `identifier` and `title` from the response. If the response carries a
GraphQL `errors` array or no `issue`, stop and report it -- the read is the
Linear half of the smoke test, so a failure here is a real signal, not something
to work around.

### 2. Append the run marker

Build a one-line Markdown bullet recording this run, then append it to
`{{LOG_FILE}}` (create the file with a `# Launch smoke-test log` heading first
if it does not yet exist):

```text
- <UTC timestamp> — cloud-launch smoke test — read <identifier>: "<title>"
```

Use `date -u +%Y-%m-%dT%H:%M:%SZ` for the timestamp. Embedding the fetched
issue title is what ties the two halves together: the line in the PR is direct
evidence the Linear read succeeded.

### 3. Open the pull request

Branch, commit just the log file, push, and open the PR:

```bash
BRANCH="{{BRANCH_PREFIX}}/$(date -u +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH"
git add "{{LOG_FILE}}"
git commit -m "chore(kikimora): launch smoke-test run marker ({{ISSUE_IDENTIFIER}})"
git push -u origin "$BRANCH"
gh pr create \
  --title "chore(kikimora): launch smoke-test run marker ({{ISSUE_IDENTIFIER}})" \
  --body "Automated smoke test of the \`tessl launch skill --cloud\` pipeline. Read \`{{ISSUE_IDENTIFIER}}\` from Linear and appended a run marker to \`{{LOG_FILE}}\`. This PR's existence proves the launch reached Linear and GitHub and opened a PR end to end."
```

`gh pr create` targets the repository's default branch, which is the base the
clone was checked out on -- that is what you want. Capture the PR URL it prints.

Then stop. Do **not** write `launch-result.json` -- recording the outcome is the
recipe's job, not the skill's; it inspects the branch and PR you left behind.
The recipe records that outcome under the fixed launch-result envelope's
`output` property, shaped by this skill's declared `schemas.output` (see
**Typed output** below) -- the PR you just opened, keyed by `pr_url`, `branch`,
`pr_number`, and `issue_identifier`.

---

## Notes

- **Idempotency / concurrency.** Each run appends a new, uniquely-timestamped
  line and opens its own branch, so re-running is always safe. Two runs in
  flight at once against the same `{{LOG_FILE}}` can conflict at merge time --
  expected for an append-to-shared-file smoke test; land them one at a time or
  point concurrent runs at different `{{LOG_FILE}}` paths.
- **Why a real PR and not a dry run.** Opening an actual PR is the point: it is
  the only thing that exercises push + `gh pr create` + the bot identity. The
  diff is a single harmless log line, trivial to close or revert.
- **Typed output.** The frontmatter declares a `schemas.output` (a local
  `$ref` to `./schemas/output.schema.json`) describing the PR this skill opens.
  On a cloud launch, `enforce-skill-schemas` composes that schema into the
  fixed launch-result envelope's `output` property (making `output` required)
  and the recipe validates the recorded result against it, so a launch of this
  skill exercises the typed-output path end to end -- the smoke test's second
  job. Declaring the contract is not "doing work": the skill still opens exactly
  the same one-line-diff PR and still writes no `launch-result.json` itself.

## What this skill deliberately omits

- **No Linear writes.** It only reads. Proving the write path is the
  `dark-factory-labeller`'s job, not this skill's -- keeping this one read-only
  makes a failed run unambiguous (a write failure can't be confused for a read
  failure).
- **No `launch-result.json`.** The recipe's launch task records the outcome by
  inspecting the branch and PR; a skill that wrote it would be doing the
  recipe's job.
- **No real work.** The appended line carries no meaning beyond "a launch ran
  here." Do not extend this skill to do useful *work* -- create a purpose-built
  skill for that and keep this one minimal so it stays a fast, unambiguous
  pipeline check. (Declaring `schemas.output` is not work: it types the PR the
  skill already opens so a launch also proves the typed-output path, without
  changing what the skill does.)

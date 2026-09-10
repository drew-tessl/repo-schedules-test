---
name: linear-digest
description: >-
  Pulls recently updated Linear issues (read-only) and writes them into a
  Markdown digest file in this repo, then opens a pull request with that
  change. Use to prove a scheduled run can reach Linear, turn what it read
  into a repo artifact, and publish it through a PR. Runs unattended: it asks
  no questions and makes no Linear writes.
---

# Linear Digest

Reads Linear, writes a doc, opens a PR. Nothing else.

Runs unattended. Never prompt for confirmation and never write to Linear.

## Inputs

Supplied by the launcher via `.cloud-launch/inputs.json`. All optional; the
defaults make the skill runnable with no inputs.

- **`{{TEAM_KEY}}`** -- Linear team key to digest. Default `EXP`.
- **`{{LOOKBACK_DAYS}}`** -- how far back to look. Default `7`.
- **`{{DIGEST_FILE}}`** -- repo-relative digest path. Default `docs/linear-digest.md`.
- **`{{BRANCH_PREFIX}}`** -- branch name prefix. Default `linear-digest`.

The run must provide the agent's `mcp__claude_ai_Linear__*` tools (read
access to issues) and GitHub credentials (`GH_TOKEN` or `GITHUB_TOKEN`) for
`gh`. If either is missing, stop and report which one. Never print or commit a
token.

## Procedure

You start in a clone of this repo, on its base branch, at the repository root.
Git already has a credential helper and a bot commit identity, so `git push`
and `gh pr create` authenticate with no setup.

### 1. Read Linear

Read Linear through the agent's own Linear MCP tools, named
`mcp__claude_ai_Linear__*`. These are available in this sandbox and are what
the `linear-triage` skill uses successfully.

Do **not** use `LINEAR_TOKEN`: it is set to a placeholder in this environment
and the API rejects it with a 401. Do not rely on `MCP_SERVERS` either; it is
empty on these runs.

1. `mcp__claude_ai_Linear__list_teams` with a query for `{{TEAM_KEY}}` to find
   the team.
2. `mcp__claude_ai_Linear__list_issues` for that team, `limit: 25`, ordered by
   most recently updated.
3. Keep only issues updated within the last `{{LOOKBACK_DAYS}}` days.

Keep each issue's identifier, title, URL, state name, and updated timestamp.

If no `mcp__claude_ai_Linear__*` tool is available, stop and report that. An
empty result is a valid outcome, not an error: write the digest with a line
saying nothing changed in the window.

### 2. Write the digest

Overwrite `{{DIGEST_FILE}}` (create parent directories if needed) with:

- An `# Linear digest` heading.
- A line giving the UTC generation time, the team key, and the window.
- One bullet per issue: `- [IDENT](url) -- title _(state)_`, newest first.
- A closing line stating how many issues were listed.

Use only fields from the response. Do not invent issues, states, or counts, and
do not carry over entries from a previous version of the file.

### 3. Open the pull request

```bash
BRANCH="{{BRANCH_PREFIX}}/$(date -u +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH"
git add "{{DIGEST_FILE}}"
git commit -m "docs: refresh Linear digest for {{TEAM_KEY}}"
git push -u origin "$BRANCH"
gh pr create \
  --title "docs: refresh Linear digest for {{TEAM_KEY}}" \
  --body "Automated digest of {{TEAM_KEY}} issues updated in the last {{LOOKBACK_DAYS}} days, read from Linear and written to \`{{DIGEST_FILE}}\`."
```

Capture the PR URL. Then stop. Do not write `launch-result.json`; the recipe
records the outcome by inspecting the branch and PR you left behind.

## Notes

- **Read-only against Linear.** The only write is the digest file in the PR.
- **Re-running is safe.** Each run overwrites the digest on its own timestamped
  branch, so concurrent runs cannot conflict in the file.
- **Which Linear access works here.** Observed on 2026-09-10: `MCP_SERVERS`
  is empty on these scheduled runs and `LINEAR_TOKEN` is a placeholder that
  401s, but the agent's own `mcp__claude_ai_Linear__*` tools do reach Linear.
  Use those.

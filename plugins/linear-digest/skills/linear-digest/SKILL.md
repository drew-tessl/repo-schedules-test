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

The environment must carry **`LINEAR_TOKEN`** (read access to issues) and
GitHub credentials (`GH_TOKEN` or `GITHUB_TOKEN`) for `gh`. If either is
missing, stop and report which one. Never print or commit a token.

## Procedure

You start in a clone of this repo, on its base branch, at the repository root.
Git already has a credential helper and a bot commit identity, so `git push`
and `gh pr create` authenticate with no setup.

### 1. Read Linear

Compute the cutoff, then query for issues updated since then:

```bash
SINCE=$(date -u -v-{{LOOKBACK_DAYS}}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -d "{{LOOKBACK_DAYS}} days ago" +%Y-%m-%dT%H:%M:%SZ)

curl -s https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"query(\$key: String!, \$since: DateTimeOrDuration!) { issues(first: 25, filter: { team: { key: { eq: \$key } }, updatedAt: { gt: \$since } }, orderBy: updatedAt) { nodes { identifier title url updatedAt state { name } } } }\",\"variables\":{\"key\":\"{{TEAM_KEY}}\",\"since\":\"$SINCE\"}}" \
  > /tmp/linear-digest.json

cat /tmp/linear-digest.json
```

If the response carries a GraphQL `errors` array, stop and report it verbatim.
An empty `nodes` array is a valid result, not an error: write the digest with a
line saying nothing changed in the window.

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
- **No MCP.** Linear is read over its GraphQL API with `LINEAR_TOKEN`. A
  schedule defined in `tessl.json` cannot request MCP servers, so a skill on
  that path must not depend on Linear MCP tools.

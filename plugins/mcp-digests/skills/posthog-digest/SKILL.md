---
name: posthog-digest
description: >-
  Reads recent project insights and events from the posthog MCP server (read-only) and writes what it
  found into a Markdown digest in this repo, then opens a pull request with
  that change. Runs unattended: it asks no questions and makes no writes to
  posthog.
---

# PostHog Digest

Read posthog, write a doc, open a PR. Nothing else.

Runs unattended. Never prompt for confirmation and never write to posthog.

## Inputs

Supplied by the launcher via `.cloud-launch/inputs.json`. All optional.

- **`{{DIGEST_FILE}}`** -- repo-relative digest path. Default `docs/posthog-digest.md`.
- **`{{LIMIT}}`** -- maximum items to list. Default `20`.
- **`{{BRANCH_PREFIX}}`** -- branch name prefix. Default `posthog-digest`.

The run must provide the **posthog MCP server**, registered on this workspace
and reachable as `posthog` through the Tessl MCP gateway. GitHub credentials
(`GH_TOKEN` or `GITHUB_TOKEN`) must be present for `gh`. If either is
missing, stop and report which one. Never print or commit a token.

## Procedure

You start in a clone of this repo, on its base branch, at the repository root.
Git already has a credential helper and a bot commit identity, so `git push`
and `gh pr create` authenticate with no setup.

### 1. Read posthog

**List the MCP tools available to you first and use those exact names.** Do not
assume a prefix: the gateway may expose them as `mcp__posthog__*`,
`mcp__drew-test_posthog__*`, or another form. Match on the tool names you
actually see.

1. List the projects you can see, and pick the first one unless an input names another.
2. List that project's insights (or saved queries), newest first, at most `{{LIMIT}}`.
3. For each keep its name, URL, and last-modified timestamp.

If no posthog MCP tool is available, stop and report that, and say which tool
names you did see. An empty result is a valid outcome, not an error: write the
digest with a line saying nothing was found.

### 2. Write the digest

Overwrite `{{DIGEST_FILE}}` (create parent directories if needed) with:

- A `# PostHog Digest` heading.
- A line giving the UTC generation time and the source.
- One bullet per item, newest first, each linking to the item where a URL exists.
- A closing line stating how many items were listed.

Use only values returned by the MCP tools. Do not invent items, and do not
carry anything over from a previous version of the file.

### 3. Open the pull request

```bash
BRANCH="{{BRANCH_PREFIX}}/$(date -u +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH"
git add "{{DIGEST_FILE}}"
git commit -m "docs: refresh posthog digest"
git push -u origin "$BRANCH"
gh pr create --title "docs: refresh posthog digest" \
  --body "Automated digest read from the posthog MCP server and written to \`{{DIGEST_FILE}}\`."
```

Capture the PR URL, then stop. Do not write `launch-result.json`; the recipe
records the outcome by inspecting the branch and PR you left behind.

## Notes

- **Read-only.** The only write is the digest file in the PR.
- **Re-running is safe.** Each run overwrites the digest on its own timestamped
  branch, so concurrent runs cannot conflict in the file.

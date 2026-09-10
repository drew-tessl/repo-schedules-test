---
name: linear-triage
description: >-
  Triage Linear issues in a team's Triage state. Categorizes issues as
  straightforward, needs-discussion, or stale/duplicate. Optionally scopes
  the straightforward ones with effort estimates via parallel sub-agents,
  then recommends which to delegate to the Oz Linear agent.
  Use when the user asks to triage a Linear team's triage inbox.
---

# Linear Triage

## Workflow

1. **Find the team** — `mcp__claude_ai_Linear__list_teams` with a `query`.
2. **Resolve the triage state ID** — `mcp__claude_ai_Linear__list_issue_statuses` for the team; pick the entry with `type === "triage"`.
3. **List issues** — `mcp__claude_ai_Linear__list_issues` with `team`, `state` (the triage state ID), `limit: 50`, `includeArchived: false`. Paginate if `hasNextPage`.
4. **Categorize each issue** into one of:
   - **Straightforward** — clear fix, unambiguous desired behavior, no open product questions
   - **Needs discussion or investigation** — requires a product decision, repro steps, design input, or further research
   - **Stale / duplicate candidate** — empty description, very old with no activity, or clearly duplicates a newer issue
5. **Scope the straightforward issues** — spawn parallel `Agent` calls with `subagent_type: Explore` (read-only). Split issues into groups and assign each sub-agent a group. Each sub-agent should:
   - Read the issue title, description, and any linked context
   - Return an effort rating for each issue in its group:
     - **Small** — well-understood, self-contained change
     - **Medium** — moderate complexity or cross-cutting concern
     - **Large** — significant scope or architectural impact
     - **Unknown** — needs a product decision or more repro before estimating
6. **Recommend Oz delegation candidates** — the Small-rated issues from step 5.
7. **Confirm before delegating** — present the user with a summary table of all issues proposed for delegation (issue ID, title, effort rating) and ask for explicit approval of the full list. Do not proceed until the user confirms.
8. **(On confirmation) Delegate** — `mcp__claude_ai_Linear__save_issue` with `id` and `delegate: "Oz"`, in parallel.

## Gotchas

- **Oz is an agent, not a user.** "Assign to Oz" means setting the `delegate` field, not `assignee`. Confirm with the user before delegating.
- **`list_issues` with large limits can fail** with a proxy error. Use `limit: 50`; if the result is too large to read inline, parse it from the persisted tool-result file (see step 3).
- **Don't modify issues** until the user explicitly authorizes it.
- **Always identify yourself as an agent if you comment in linear**. Write: "Comment by {agent} running `/linear-triage`"

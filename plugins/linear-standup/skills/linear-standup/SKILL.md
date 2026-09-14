---
name: linear-standup
description: Fetch recent Linear issues and write a daily standup report to docs/linear-standup.md.
---

# Linear standup

1. Run the Linear credential pre-flight before any other work:

   ```bash
   bash "$(git rev-parse --show-toplevel)/plugins/linear-standup/skills/linear-standup/scripts/linear.sh" "LINEAR_TOKEN"
   ```

   A non-zero result means stop before doing anything else.
2. Query Linear for the 10 most recently updated issues with `LINEAR_TOKEN`.
3. Include these fields: identifier, title, updatedAt, state name, assignee name, team key, and URL.
4. Write `docs/linear-standup.md` with:
   - `# Linear standup`
   - Generated timestamp.
   - One markdown list item per issue with linked identifier, title, team, state, assignee or `Unassigned`, and updated timestamp.
5. Open a pull request with only the standup report changes.

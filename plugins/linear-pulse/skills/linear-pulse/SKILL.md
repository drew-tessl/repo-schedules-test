---
name: linear-pulse
description: Fetch recent Linear issues and write a pulse report to docs/linear-pulse.md.
---

# Linear pulse

1. Run the Linear credential pre-flight before any other work:

   ```bash
   bash "$(git rev-parse --show-toplevel)/plugins/linear-pulse/skills/linear-pulse/scripts/linear.sh" "LINEAR_TOKEN"
   ```

   A non-zero result means stop before doing anything else.
2. Query Linear for the 10 most recently updated issues with `LINEAR_TOKEN`.
3. Include these fields: identifier, title, updatedAt, state name, assignee name, team key, and URL.
4. Write `docs/linear-pulse.md` with:
   - `# Linear pulse`
   - Generated timestamp.
   - One markdown list item per issue with linked identifier, title, team, state, assignee or `Unassigned`, and updated timestamp.
5. Leave no other file changes.

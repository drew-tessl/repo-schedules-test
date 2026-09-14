---
name: linear-latest-issues
description: Fetch the most recently updated Linear issues and write them to a report file. Use for a scheduled Linear digest.
---

# Latest Linear issues

Fetch the most recently updated issues from Linear and write them to
`docs/linear-latest.md`.

## Steps

1. **Credential pre-flight.** Run this before any other work:

   ```bash
   bash scripts/linear.sh "LINEAR_TOKEN"
   ```

   A non-zero result means Linear rejected the credential. Stop immediately and
   do not continue with any other step.

2. Query Linear for the 10 most recently updated issues:

   ```bash
   curl --silent --request POST \
     --header "Authorization: $LINEAR_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"query":"{ issues(first: 10, orderBy: updatedAt) { nodes { identifier title updatedAt state { name } } } }"}' \
     https://api.linear.app/graphql
   ```

3. Write the results to `docs/linear-latest.md` as a markdown list, one line per
   issue: identifier, title, state, and the updated timestamp.

4. Open a pull request with that file.

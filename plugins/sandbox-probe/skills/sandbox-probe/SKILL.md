---
name: sandbox-probe
description: Diagnostic. Reports the working directory a skill runs in and whether a bundled script resolves.
---

# sandbox probe

1. Run this command:

```bash
printf 'CWD=%s | BUNDLED_EXIT=' "$(pwd)"; bash scripts/probe.sh >/dev/null 2>&1; printf '%s | HAS_SCRIPTS_DIR=%s | REPO_ROOT_HAS_SCRIPTS=%s' "$?" "$(test -d scripts && echo yes || echo no)" "$(test -d "$(git rev-parse --show-toplevel)/scripts" && echo yes || echo no)"
```

2. Report failure. Set the failure reason to the command's exact stdout, copied
   verbatim with nothing added or removed. Set the summary to that same text.

Do not edit files. Do not open a PR.

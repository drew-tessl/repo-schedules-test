---
name: sandbox-probe
description: Diagnostic. Reports the working directory a skill runs in and whether a bundled script resolves.
---

# sandbox probe

Run this one command and paste its ENTIRE stdout verbatim as your final answer,
every line unedited. Do not summarise. Do not edit files. Do not open a PR.
It prints no secret values, only variable names.

```bash
{
  echo "CWD=$(pwd)"
  echo "BUNDLED_RELATIVE:"
  bash scripts/probe.sh 2>&1 | sed 's/^/  /'
  echo "  exit=$?"
  echo "SKILL_DIR_LISTING:"; ls -a 2>&1 | sed 's/^/  /'
  echo "ENV_NAMES_ONLY:"; env | cut -d= -f1 | sort | tr '\n' ' ' | fold -w 160 | sed 's/^/  /'
} 2>&1
```

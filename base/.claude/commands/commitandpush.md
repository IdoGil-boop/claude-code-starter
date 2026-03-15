<!-- managed by claude-code-starter -->
---
description: Stage, commit, push changes, then run /maintain
---

# Commit and Push

## Steps

1. `git add` all relevant saved changes (never `git add .`)
2. `git diff --cached --stat` to review what's staged
3. `git commit` with conventional commit message
4. `git push` (with `-u` if new branch)
5. Run `/maintain` to capture session learnings

## Rules

- Never commit `.env`, credentials, or build artifacts
- Use conventional commit format: `type: description`
- One logical change per commit (use `/commit-by-feature` for multiple)
- Ask before force-pushing

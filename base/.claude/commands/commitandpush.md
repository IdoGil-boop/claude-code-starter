<!-- managed by claude-code-starter -->
---
description: Stage, commit, push as branch, open PR, verify CI passes
---

# Commit and Push

## Default Behavior

Unless the user specifies otherwise, this command:
1. Creates a feature branch from the current changes
2. Pushes and opens a PR
3. Waits for CI to complete
4. Fixes any CI failures and re-pushes

## Steps

### 1. Stage & Commit
1. `git add` all relevant saved changes (never `git add .`)
2. `git diff --cached --stat` to review what's staged
3. `git commit` with conventional commit message

### 2. Branch & Push
1. If on `main`/`master`, create a branch: `git checkout -b feat/<short-description>` (or `fix/`, `chore/` etc. based on commit type)
2. `git push -u origin HEAD`

### 3. Open PR
1. `gh pr create --title "<commit message>" --body "<summary of changes with test plan>"`
2. Print the PR URL

### 4. Wait for CI
1. Wait 2 minutes: `sleep 120`
2. Check CI status: `gh pr checks <pr-number> --watch` or `gh run list --branch <branch> --limit 1`
3. If all checks pass → done, print success
4. If any check fails → continue to step 5

### 5. Fix CI Failures (loop up to 3 attempts)
1. Get failure details: `gh run view <run-id> --log-failed`
2. Read the error, fix the code
3. Stage, commit: `fix: resolve CI failure in <check-name>`
4. `git push`
5. Wait 2 minutes, re-check CI
6. If still failing after 3 attempts, post a PR comment explaining the blocker and notify the user

## Rules

- Never commit `.env`, credentials, or build artifacts
- Use conventional commit format: `type: description`
- One logical change per commit (use `/commit-by-feature` for multiple)
- Ask before force-pushing
- If the user says "push to main" or "push directly", skip the branch/PR flow
- If the user specifies a branch name, use that instead of auto-generating one

<!-- managed by claude-code-starter -->
---
name: deploy-after-merge
description: Deploy to production after merging a PR. SSHs into the production server, pulls latest main, builds, runs migrations, restarts services, and verifies health. If conflicts or issues arise, reports them for local fix rather than editing prod directly.
---

# Deploy After Merge

Pulls the latest `main` on the production server after a PR merge, then runs build + migrate + restart + health check. Detects conflicts and reports them for local fix rather than editing code in prod.

## When to Use

- After merging a PR into `main` on GitHub
- When you want to deploy the latest main to production
- `/deploy` or `/deploy-after-merge`

## First-Run Setup

**This skill is a template.** On first invocation in a new project, Claude must fill in the project-specific values below, then save the customized skill to the project. Fields that need to be provided:

| Field | Example | Notes |
|-------|---------|-------|
| `SSH_METHOD` | `gcloud compute ssh <instance> --zone=<zone> --command` OR `ssh -i <key> <user>@<host>` | How to run a remote command |
| `REPO_PATH` | `/opt/myapp` or `/home/ubuntu/myapp` | Absolute path to the git repo on the server |
| `COMPOSE_FILE` | `docker-compose.prod.yml` or `docker-compose.gcp.yml` | The production compose file |
| `BACKEND_CONTAINER` | `myapp-backend-1` | For log tailing on health check failure |
| `HEALTH_URL` | `http://localhost:8000/api/health` | Endpoint that returns 200 when healthy |
| `DEPLOY_SCRIPT` | `./scripts/deploy.sh --yes` (preferred) or inline commands | If the repo has a deploy script, use it |

Look for hints in the repo first:
- `docker-compose*.yml` → compose file and container names
- `scripts/deploy.sh` → if present, use it via `$DEPLOY_SCRIPT`
- `docs/reference/PRODUCTION_DEPLOYMENT.md` or similar → server details
- `gcloud compute instances list` → for GCP-hosted projects
- `.env.example` / `README.md` → for health endpoint

If any field can't be discovered from the repo, ask the user with AskUserQuestion, then save the populated values inline in this file so future runs don't re-ask.

## Workflow

Replace `$SSH_CMD` below with the project-specific SSH_METHOD.

### Step 1 — Pre-flight Check

```bash
$SSH_CMD "cd $REPO_PATH && echo '=== BRANCH ===' && git branch --show-current && echo '=== STATUS ===' && git status --short && echo '=== CURRENT COMMIT ===' && git log --oneline -1"
```

**If dirty working tree**: STOP. Report the dirty files to the user. Do NOT proceed — dirty files usually mean someone edited prod directly.

**Decision gate**: If clean (or only has expected untracked files like `.env.prod`), proceed to Step 2. Otherwise ask the user whether to stash or abort.

### Step 2 — Pull Latest Main

```bash
$SSH_CMD "cd $REPO_PATH && git fetch origin && git pull origin main"
```

**If pull fails (conflicts)**:
1. Report the exact conflict files and error message
2. Run `git merge --abort` on the server to restore clean state
3. Tell the user: "Fix the conflict locally, push, then re-run /deploy-after-merge"
4. STOP — do not proceed

**If pull succeeds**: Proceed to Step 3.

### Step 3 — Build and Deploy

**Preferred** — if the repo has `scripts/deploy.sh`:

```bash
$SSH_CMD "cd $REPO_PATH && $DEPLOY_SCRIPT"
```

**Fallback** — inline commands when no deploy script exists:

```bash
# Build images
$SSH_CMD "cd $REPO_PATH && docker compose -f $COMPOSE_FILE build"

# Run migrations (adjust command for the project's migration tool)
$SSH_CMD "cd $REPO_PATH && docker compose -f $COMPOSE_FILE run --rm backend alembic upgrade head"

# Restart services
$SSH_CMD "cd $REPO_PATH && docker compose -f $COMPOSE_FILE up -d"
```

**If build fails**: Previous containers still running (safe). Report error, fix locally.
**If migration fails**: Report error — "Fix locally, test with fresh DB, push, then re-run".

### Step 4 — Health Check

```bash
# Container status
$SSH_CMD "docker compose -f $REPO_PATH/$COMPOSE_FILE ps"

# Health endpoint
$SSH_CMD "curl -sf $HEALTH_URL || echo 'HEALTH CHECK FAILED'"

# Backend logs on failure
$SSH_CMD "docker logs $BACKEND_CONTAINER --tail 30"
```

### Step 5 — Verify Alignment

```bash
$SSH_CMD "cd $REPO_PATH && echo 'PROD:' && git log --oneline -1 && echo 'ORIGIN:' && git log --oneline -1 origin/main"
```

Report final status:
- Commit hash on prod vs origin/main (should match)
- Container status (all healthy?)
- Health check result

## Error Recovery

| Problem | Action |
|---------|--------|
| Dirty working tree on prod | Report files, ask user to decide |
| Pull conflict | `git merge --abort`, fix locally |
| Migration failure | Report error, fix locally |
| Docker build failure | Old containers still running, fix locally |
| Health check failure | Tail backend logs, report error |
| Permission denied | Check repo ownership matches login user (`chown` if needed) |
| Container OOM | Check `docker stats`, may need to adjust memory limits |

## Key Principle

**Never edit code on the production server.** All fixes happen locally, get pushed, and this skill pulls them down cleanly. If anything goes wrong, abort and fix locally.

## Companion: scripts/deploy.sh

Projects should pair this skill with a `scripts/deploy.sh` script that encapsulates build + migrate + restart + health check. A reference implementation:

```bash
#!/usr/bin/env bash
set -euo pipefail
COMPOSE_FILE="docker-compose.prod.yml"  # adjust per project
BACKEND_CONTAINER="myapp-backend-1"
HEALTH_URL="http://localhost:8000/api/health"

cd "$(git rev-parse --show-toplevel)"

# Pre-flight
[ "$(git branch --show-current)" = "main" ] || { echo "Not on main"; exit 1; }
[ "${1:-}" = "--yes" ] || { read -rp "Deploy $(git log --oneline -1)? [y/N] " c; [[ "$c" =~ ^[Yy]$ ]] || exit 0; }

# Build, migrate, restart
docker compose -f "$COMPOSE_FILE" build
docker compose -f "$COMPOSE_FILE" run --rm backend alembic upgrade head
docker compose -f "$COMPOSE_FILE" up -d

# Health check with retries
sleep 3
for i in $(seq 1 10); do
    curl -sf "$HEALTH_URL" > /dev/null && break
    [ "$i" -eq 10 ] && { docker logs "$BACKEND_CONTAINER" --tail 30; exit 1; }
    sleep 2
done

echo "Deploy complete: $(git log --oneline -1)"
```

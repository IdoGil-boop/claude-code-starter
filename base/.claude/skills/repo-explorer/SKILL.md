<!-- managed by claude-code-starter -->
---
name: repo-explorer
description: Quickly map a repository's structure, key entry points, and architecture.
---

# Repo Explorer

## When to Use

- First time working in a new area of the codebase
- Need to understand how modules connect
- Looking for where specific logic lives

## Workflow

### Step 1 — Map the structure
```bash
find . -type f -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.go" | head -50
```

### Step 2 — Find entry points
Look for: main files, route definitions, task registrations, CLI entry points.

### Step 3 — Identify key nodes
For each major directory:
- What is its responsibility?
- What does it export?
- What does it depend on?

### Step 4 — Map connections
```bash
# Find imports/requires between modules
grep -rn "from\|import\|require" {{SOURCE_DIR}}/ | head -30
```

## Output Format

```
## Architecture Map

### Entry Points
- {{BACKEND_DIR}}/main.py — API server
- {{BACKEND_DIR}}/worker.py — Background tasks

### Key Modules
- {{SOURCE_DIR}}/models/ — Data models
- {{SOURCE_DIR}}/routes/ — API endpoints
- {{SOURCE_DIR}}/services/ — Business logic
```

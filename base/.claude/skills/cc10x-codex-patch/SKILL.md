<!-- managed by claude-code-starter -->
# cc10x Codex Patch (Post-Update)

Re-apply custom patches to the cc10x-router after a plugin update overwrites the cached router file.

## When to Run

- cc10x plugin was updated (BUILD workflows no longer include codex-review step)
- New session and codex-review tasks aren't being created
- Router file was reset or recreated

## Workflow

### Step 1: Find the router file
```bash
find ~/.claude/plugins/cache/cc10x -name "SKILL.md" -path "*/cc10x-router/*" 2>/dev/null
```

### Step 2: Check if patch is needed
```bash
grep -c "codex-review" "$ROUTER_FILE"
```
If > 0, already patched — stop.

### Step 3: Apply patches
Adapt the edits to the current router file structure. Key patches:
1. Add `[codex-review]` to BUILD chain between reviewers and verifier
2. Add codex task to BUILD task hierarchy
3. Wire verifier dependency through codex task

### Step 4: Verify
```bash
grep -c "codex-review" "$ROUTER_FILE"  # Should be 5+
```

## Rules

- **Idempotent** — check before each patch
- **Version-aware** — adapt if router structure changed
- **Only patch BUILD** — leave DEBUG/REVIEW/PLAN unchanged

## Prerequisites

Project must have:
- `.claude/scripts/codex_review.py` — the review script
- `OPENAI_API_KEY_CODE_REVIEW` environment variable

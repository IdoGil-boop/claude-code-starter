<!-- managed by claude-code-starter -->
---
description: Structured debugging workflow with pattern sweep and knowledge tracking
---

# Bugfix

Launch the structured debug workflow for a bug or issue.

> **NEVER skip phases. Every gate must be printed before proceeding to the next phase.**
> Even if the fix seems obvious, follow the full workflow — obvious fixes that skip reproduction are the #1 source of regressions.

## Workflow (all steps mandatory)

1. **GATE 0 — Search existing knowledge** (MANDATORY):
   - Read `docs/gotchas.md` for known gotchas matching this symptom
   - Read `docs/debug-history.md` for previously fixed similar bugs
   - Search instincts for debugging domain matches
   - Print ✅ GATE 0 before proceeding

2. **GATE 1 — Reproduce** (MANDATORY):
   - Actually trigger the bug and observe the failure
   - Print ✅ GATE 1 with reproduction steps and observed error

3. **GATE 2 — Isolate** (MANDATORY):
   - Narrow to specific files and functions
   - Print ✅ GATE 2 with location

4. **GATE 3 — Root Cause** (MANDATORY):
   - Apply 5 Whys to find the actual root cause
   - Print ✅ GATE 3 with root cause statement

5. **GATE 3b — Spawn test writer** (MANDATORY):
   - Spawn `debug-test-writer` agent **in background** with symptom, root cause, affected code, and reproduction steps
   - Print ✅ GATE 3b with agent ID

6. **GATE 4 — Hypothesize** (MANDATORY):
   - Propose and evaluate candidate fixes
   - Print ✅ GATE 4 with chosen approach

7. **GATE 5 — Fix** (MANDATORY):
   - Apply the minimal fix
   - Print ✅ GATE 5 with files changed

8. **GATE 5b — Pattern sweep** (MANDATORY):
   - Extract bug pattern and grep the entire codebase for siblings
   - Fix ALL instances in the same pass
   - Print ✅ GATE 5b with search terms and siblings found

9. **GATE 6 — Verify** (MANDATORY):
   - Collect parallel test writer results
   - Run regression tests — must turn RED→GREEN
   - Run full test suite: `{{TEST_CMD}}`
   - Run linter: `{{LINT_CMD}}`
   - Confirm original reproduction no longer triggers the bug
   - Print ✅ GATE 6 with all results

10. **GATE 7 — Document** (MANDATORY):
    - Add gotcha to `docs/gotchas.md` if the bug was counter-intuitive
    - **Always** append entry to `docs/debug-history.md` with root cause and fix
    - Consider creating a debugging instinct if pattern is likely to recur
    - Print ✅ GATE 7 confirming all docs updated

> **The bugfix is NOT complete until all 10 gates are printed and passing.**

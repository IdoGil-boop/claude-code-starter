<!-- managed by claude-code-starter -->
---
description: Structured debugging workflow with pattern sweep and knowledge tracking
---

# Debug

Launch the structured debug workflow for a bug or issue.

## Steps

1. **Search existing knowledge**:
   - Read `docs/gotchas.md` for known gotchas matching this symptom
   - Read `docs/debug-history.md` for previously fixed similar bugs
   - If a match is found, apply known fix and skip to verification

2. **Run the 7-phase debug workflow** (from `debug-workflow` skill):
   - Reproduce → Isolate → Trace → **Spawn test writer** → Hypothesize → Fix → Verify → Document
   - After Phase 3 (root cause identified), spawn `debug-test-writer` agent **in background**
   - The test writer writes failing regression tests in parallel while the fix is developed
   - At Phase 6, the fix must turn the parallel tests from RED to GREEN

3. **Pattern sweep** (BUGSTONE — mandatory after every fix):
   - Extract the bug pattern
   - `grep -rn` across the entire codebase for siblings
   - Fix ALL instances in the same pass

4. **Update project knowledge**:
   - Add gotcha to `docs/gotchas.md` if the bug was counter-intuitive
   - Append entry to `docs/debug-history.md` with root cause and fix
   - Consider creating a debugging instinct if pattern is likely to recur

5. **Post-fix verification**:
   - Run full test suite: `{{TEST_CMD}}`
   - Run linter: `{{LINT_CMD}}`
   - Confirm original reproduction no longer triggers the bug

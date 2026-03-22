<!-- managed by claude-code-starter -->
---
name: debug-workflow
description: Structured debugging skill with 7-phase workflow, BUGSTONE pattern sweep, gotcha tracking, debug history, and pre/post hooks.
user_invocable: true
---

# Debug Workflow

Structured debugging methodology that finds root causes, sweeps for sibling bugs, and builds project-level knowledge.

## Before You Start

**Search existing knowledge first** — before diving into code:
1. Read `docs/gotchas.md` — check if this bug matches a known gotcha
2. Read `docs/debug-history.md` — check if a similar bug was fixed before
3. Search instincts: `grep -r "domain: debugging" .claude/instincts/`
4. If a match is found, apply the known fix and skip to Phase 6 (Verify)

## Phase 1: Reproduce

Consistently trigger the bug before attempting any fix.

- Capture: error message, stack trace, environment, triggering input
- Document exact reproduction steps (commands, URLs, user actions)
- If intermittent: establish frequency and conditions (timing, load, data shape)
- **Pre-hook runs automatically**: cleans caches (`.next/`, `dist/`, `__pycache__/`, `.cache/`) to ensure clean reproduction

**Output**: A reproducible trigger you can run on demand.

## Phase 2: Isolate

Narrow the problem space.

- Use binary search debugging: comment out halves of suspect code to narrow the location
- Use conditional breakpoints or targeted logging at suspect boundaries
- Check recent changes: `git log --oneline -20` and `git diff HEAD~5` for related commits
- Distinguish primary failure from cascading symptoms

**Output**: The specific file(s) and function(s) where the bug lives.

## Phase 3: Trace / Root Cause

Work backward from where the problem manifests.

- Reconstruct context: request parameters, system state, execution timing
- Apply **5 Whys**: ask "why" iteratively to drill past symptoms to root cause
  ```
  Why 500? → DB timeout → Full table scan → Missing index → Migration not applied → No CI check
  ```
- Add targeted logging if needed (iterative logging loop):
  1. Add loggers around suspect code
  2. Run reproduction
  3. If root cause not visible, add more loggers and repeat

**Output**: A clear root cause statement (not just "it was broken here" but *why*).

## Phase 3b: Spawn Parallel Test Writer

**Immediately after identifying the root cause**, spawn the `debug-test-writer` agent in the background:

```
Agent(debug-test-writer, run_in_background=true):
  Symptom: <what the user observed>
  Root cause: <why it happens>
  Affected code: <file paths and function names>
  Reproduction: <how to trigger the bug>
```

The test writer works **in parallel** with Phases 4-5:
- It reads the affected code and existing test patterns
- It writes regression tests that **fail now** (RED) and will **pass after the fix** (GREEN)
- It verifies the tests actually fail before the fix
- It does NOT modify source code — only test files

> This is parallel TDD: tests are written against the *bug*, not the fix. By the time the fix lands, the tests are ready.

## Phase 4: Hypothesize

Generate candidate fixes before writing code.

- Propose 1-3 targeted fixes based on root cause
- Evaluate each: correctness, side effects, regression risk
- Prefer the **minimal change** that addresses root cause, not symptoms
- AI suggestions are hypotheses — never auto-apply without verification

**Output**: A chosen fix approach with rationale.

## Phase 5: Fix

Apply the fix (while the test writer works in parallel).

- Make the minimal change that addresses root cause
- Follow existing code patterns and style
- The parallel `debug-test-writer` agent is writing regression tests concurrently
- **Immediately after fixing**: proceed to Phase 5b (Pattern Sweep)

### Phase 5b: Pattern Sweep (BUGSTONE)

After fixing the bug, sweep the codebase for siblings:

1. **Extract the pattern**: What was wrong and what the correct usage looks like
   - Example: "API X was called without null-checking the return value"
2. **Search broadly**: `grep -rn` the pattern across ALL relevant file types
   - Search backend AND frontend, tests AND production code
   - Use multiple search terms (function name, error pattern, anti-pattern)
3. **Review each hit**: Confirm whether it's a genuine instance of the same bug class
4. **Fix ALL instances** in the same commit — never fix just one

> A reviewer finding the same bug in a different file on the next round is a wasted cycle.

**Output**: All sibling bugs fixed in the same pass.

## Phase 6: Verify (Fix Meets Tests)

Confirm the fix works, the parallel tests pass, and nothing else broke.

### 6a. Collect Parallel Test Results
- Wait for the `debug-test-writer` agent to complete (if not already done)
- Review the regression tests it wrote — ensure they target the actual bug
- The tests should have been verified as **failing (RED)** before the fix

### 6b. Run Tests — Must Turn GREEN
- Run the new regression tests: `{{TEST_CMD}} <test_file> -v`
- They MUST pass now that the fix is applied
- If any regression test still fails:
  - Either the fix is incomplete → revisit Phase 5
  - Or the test targets the wrong thing → adjust the test
- This is the **RED→GREEN contract**: tests failed before the fix, pass after

### 6c. Full Verification
- Run the original reproduction steps — must no longer trigger the bug
- Run full test suite (not just the new tests): `{{TEST_CMD}}`
- Run linter and type checker: `{{LINT_CMD}}` and `{{TYPE_CHECK_CMD}}`
- Check for regressions in adjacent functionality
- **Post-hook runs automatically**: reminds about pattern sweep and test verification

**Output**: All tests green (including new regression tests), reproduction no longer triggers bug.

## Phase 7: Document

Record what you learned for future debugging sessions.

### 7a. Update Gotchas (if applicable)

If the bug was caused by counter-intuitive behavior (not just a typo), add to `docs/gotchas.md`:

```markdown
### [Short descriptive title]
**Symptom:** What the developer observes
**Why it happens:** The underlying cause
**Fix/Workaround:** The correct approach
**Example:**
  - Bad: `code that triggers the gotcha`
  - Good: `code that avoids the gotcha`
**Related:** [link to commit or PR]
```

### 7b. Update Debug History

Append to `docs/debug-history.md`:

```markdown
### [Date] — [Short title]
**Symptom:** [What was observed]
**Root cause:** [The actual underlying issue]
**Fix:** [What was changed, with commit ref]
**Pattern sweep:** [How many siblings found and fixed, or "none"]
**Time to fix:** [Rough estimate]
```

### 7c. Consider Instinct

If this bug pattern is likely to recur, create a debugging instinct in `.claude/instincts/personal/`:
```yaml
---
id: check-null-before-api-x
trigger: "when calling API X"
confidence: 0.5
domain: "debugging"
source: "bug-fix"
created: "{{today}}"
---
```

## Quick Reference

| Phase | Goal | Key Technique |
|-------|------|---------------|
| 1. Reproduce | Reliable trigger | Clean env + exact steps |
| 2. Isolate | Narrow location | Binary search / git bisect |
| 3. Trace | Root cause | 5 Whys + iterative logging |
| 3b. Test Writer | Parallel regression tests | `debug-test-writer` agent (background) |
| 4. Hypothesize | Candidate fixes | Minimal change principle |
| 5. Fix | Apply + sweep | BUGSTONE pattern sweep |
| 6. Verify | Fix meets tests (RED→GREEN) | Parallel tests + full suite + repro |
| 7. Document | Build knowledge | Gotchas + history + instincts |

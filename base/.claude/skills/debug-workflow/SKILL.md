<!-- managed by claude-code-starter -->
---
name: debug-workflow
description: Structured debugging skill with 7-phase workflow, BUGSTONE pattern sweep, gotcha tracking, debug history, and pre/post hooks.
user_invocable: true
---

# Debug Workflow

Structured debugging methodology that finds root causes, sweeps for sibling bugs, and builds project-level knowledge.

> **MANDATORY: Every phase must be completed in order. NEVER skip a phase.**
> After completing each phase, print the phase gate checkpoint (shown at the end of each phase) before proceeding.
> If you are tempted to jump ahead because the fix "seems obvious" — STOP. Obvious fixes that skip reproduction and root cause analysis are the #1 source of regressions.

---

## Phase 0: Search Existing Knowledge

**MANDATORY — always run before touching any code.**

1. Read `docs/gotchas.md` — check if this bug matches a known gotcha
2. Read `docs/debug-history.md` — check if a similar bug was fixed before
3. Search instincts: `grep -r "domain: debugging" .claude/instincts/`

If a match is found, **still complete all phases** — but use the prior knowledge to accelerate. Prior matches can be wrong, outdated, or only partially applicable. Verify everything.

```
✅ GATE 0: Knowledge search complete
  - Gotchas checked: [yes/no, any matches]
  - Debug history checked: [yes/no, any matches]
  - Instincts checked: [yes/no, any matches]
```

---

## Phase 1: Reproduce

**MANDATORY — never attempt a fix without first reproducing the bug.**

- Capture: error message, stack trace, environment, triggering input
- Document exact reproduction steps (commands, URLs, user actions)
- If intermittent: establish frequency and conditions (timing, load, data shape)
- **Pre-hook runs automatically**: cleans caches (`.next/`, `dist/`, `__pycache__/`, `.cache/`) to ensure clean reproduction
- **Actually run the reproduction** and observe the failure yourself

```
✅ GATE 1: Bug reproduced
  - Reproduction command/steps: [what you ran]
  - Observed error: [exact error or wrong behavior]
  - Reproducible: [yes/intermittent/blocked — if blocked, STOP and ask user]
```

---

## Phase 2: Isolate

**MANDATORY — narrow before you fix.**

- Use binary search debugging: comment out halves of suspect code to narrow the location
- Use conditional breakpoints or targeted logging at suspect boundaries
- Check recent changes: `git log --oneline -20` and `git diff HEAD~5` for related commits
- Distinguish primary failure from cascading symptoms

```
✅ GATE 2: Bug isolated
  - File(s): [paths]
  - Function(s): [names]
  - Narrowed to: [specific lines or logic block]
```

---

## Phase 3: Trace / Root Cause

**MANDATORY — understand WHY before you fix WHAT.**

- Reconstruct context: request parameters, system state, execution timing
- Apply **5 Whys**: ask "why" iteratively to drill past symptoms to root cause
  ```
  Why 500? → DB timeout → Full table scan → Missing index → Migration not applied → No CI check
  ```
- Add targeted logging if needed (iterative logging loop):
  1. Add loggers around suspect code
  2. Run reproduction
  3. If root cause not visible, add more loggers and repeat
- Do NOT proceed until you can state the root cause clearly

```
✅ GATE 3: Root cause identified
  - Root cause: [clear statement of WHY, not just WHERE]
  - 5 Whys chain: [the chain you followed]
  - Confidence: [high/medium/low — if low, add more logging and repeat]
```

---

## Phase 3b: Spawn Parallel Test Writer

**MANDATORY — spawn immediately after Gate 3 passes.**

Spawn the `debug-test-writer` agent in the background:

```
Agent(debug-test-writer, run_in_background=true):
  Symptom: <what the user observed>
  Root cause: <why it happens — from Gate 3>
  Affected code: <file paths and function names — from Gate 2>
  Reproduction: <how to trigger the bug — from Gate 1>
```

The test writer works **in parallel** with Phases 4-5:
- It reads the affected code and existing test patterns
- It writes regression tests that **fail now** (RED) and will **pass after the fix** (GREEN)
- It verifies the tests actually fail before the fix
- It does NOT modify source code — only test files

> This is parallel TDD: tests are written against the *bug*, not the fix. By the time the fix lands, the tests are ready.

```
✅ GATE 3b: Test writer spawned
  - Agent launched: [yes — include agent ID]
  - Context provided: [symptom, root cause, affected code, reproduction]
```

---

## Phase 4: Hypothesize

**MANDATORY — think before you type.**

- Propose 1-3 targeted fixes based on root cause
- Evaluate each: correctness, side effects, regression risk
- Prefer the **minimal change** that addresses root cause, not symptoms
- AI suggestions are hypotheses — never auto-apply without verification

```
✅ GATE 4: Fix approach chosen
  - Candidates considered: [list with brief pros/cons]
  - Chosen approach: [which one and why]
  - Risk assessment: [what could go wrong]
```

---

## Phase 5: Fix

**MANDATORY — apply the chosen fix.**

- Make the minimal change that addresses root cause
- Follow existing code patterns and style
- The parallel `debug-test-writer` agent is writing regression tests concurrently
- **Immediately after fixing**: proceed to Phase 5b (Pattern Sweep)

```
✅ GATE 5: Fix applied
  - Files changed: [list]
  - Change summary: [what was changed and why]
```

---

### Phase 5b: Pattern Sweep (BUGSTONE)

**MANDATORY — never fix just one instance.**

After fixing the bug, sweep the codebase for siblings:

1. **Extract the pattern**: What was wrong and what the correct usage looks like
   - Example: "API X was called without null-checking the return value"
2. **Search broadly**: `grep -rn` the pattern across ALL relevant file types
   - Search backend AND frontend, tests AND production code
   - Use multiple search terms (function name, error pattern, anti-pattern)
3. **Review each hit**: Confirm whether it's a genuine instance of the same bug class
4. **Fix ALL instances** in the same commit — never fix just one

> A reviewer finding the same bug in a different file on the next round is a wasted cycle.

```
✅ GATE 5b: Pattern sweep complete
  - Pattern searched: [what you grepped for]
  - Search terms used: [list]
  - Hits found: [count]
  - Siblings fixed: [count, or "none found"]
  - Files affected: [list, or "none"]
```

---

## Phase 6: Verify (Fix Meets Tests)

**MANDATORY — the fix is not done until tests prove it.**

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

```
✅ GATE 6: Verification passed
  - Regression tests: [count] written, all GREEN
  - RED→GREEN confirmed: [yes/no]
  - Full test suite: [pass/fail — if fail, STOP and investigate]
  - Original reproduction: [no longer triggers bug: yes/no]
  - Linter/type check: [pass/fail]
```

---

## Phase 7: Document

**MANDATORY — every fix must leave a trail.**

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

**Always** append to `docs/debug-history.md`:

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

```
✅ GATE 7: Documentation complete
  - Gotcha added: [yes/no — if no, why not]
  - Debug history updated: [yes — MANDATORY]
  - Instinct created: [yes/no — if no, why not]
```

---

## Quick Reference

| Phase | Goal | Key Technique | Gate |
|-------|------|---------------|------|
| 0. Knowledge Search | Check prior fixes | gotchas + history + instincts | ✅ GATE 0 |
| 1. Reproduce | Reliable trigger | Clean env + exact steps | ✅ GATE 1 |
| 2. Isolate | Narrow location | Binary search / git bisect | ✅ GATE 2 |
| 3. Trace | Root cause | 5 Whys + iterative logging | ✅ GATE 3 |
| 3b. Test Writer | Parallel regression tests | `debug-test-writer` agent (background) | ✅ GATE 3b |
| 4. Hypothesize | Candidate fixes | Minimal change principle | ✅ GATE 4 |
| 5. Fix | Apply fix | Minimal change | ✅ GATE 5 |
| 5b. Pattern Sweep | Find sibling bugs | BUGSTONE grep sweep | ✅ GATE 5b |
| 6. Verify | Fix meets tests (RED→GREEN) | Parallel tests + full suite + repro | ✅ GATE 6 |
| 7. Document | Build knowledge | Gotchas + history + instincts | ✅ GATE 7 |

> **Completion rule**: The bugfix is NOT done until ALL gates are printed and passing. If any gate fails, resolve it before proceeding to the next phase.

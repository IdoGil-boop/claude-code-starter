<!-- managed by claude-code-starter -->
# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

Examples:
- `feat: add batch email scheduler for account-level sends`
- `fix: correct race condition in concurrent updates`
- `refactor: extract decision logic into single function`
- `test: add TDD coverage for token-based auth endpoints`

## Pull Request Workflow

When creating PRs:
1. Analyze FULL commit history (not just latest commit)
2. Use `git diff main...HEAD` to see all changes from branch point
3. Draft comprehensive PR summary covering all commits
4. Include test plan with specific verification steps
5. Push with `-u` flag if new branch

## Feature Implementation Workflow

### 1. Plan First
- Use **planner** agent to create implementation plan
- Identify single source of truth (check CLAUDE.md)
- If logic already exists elsewhere, delegate — do not create competing implementations
- Break down into phases with clear milestones

### 2. TDD Approach
- Write tests first (RED) — `{{TEST_CMD}} {{TEST_DIR}}/test_feature.py -x`
- Implement to pass tests (GREEN)
- Refactor (IMPROVE)
- Verify coverage: `{{COVERAGE_CMD}}`

### 3. Code Review
- Use code review agents after writing code
- Address CRITICAL and HIGH issues immediately
- Fix MEDIUM issues when possible
- Run linters: `{{LINT_CMD}}`, `{{TYPE_CHECK_CMD}}`

### 4. Commit & Push
- Detailed commit messages following conventional format
- One logical change per commit
- Include migrations with model changes

## Branch Naming

- `feat/short-description` — New features
- `fix/short-description` — Bug fixes
- `refactor/short-description` — Code restructuring
- `chore/short-description` — Maintenance tasks

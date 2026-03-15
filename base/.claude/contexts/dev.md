<!-- managed by claude-code-starter -->
# Development Mode

Active development context. Prioritize working code, tests, and clean commits.

## Focus Areas

- Write code following project conventions (see `.claude/rules/`)
- Run tests after changes: `{{TEST_CMD}} {{TEST_DIR}}/ -x`
- Run linter before committing: `{{LINT_CMD}} {{SOURCE_DIR}}/`
- Use TDD for new features (RED → GREEN → REFACTOR)
- Keep functions <50 lines, files <800 lines

## Key Paths

- Source: `{{SOURCE_DIR}}/`
- Tests: `{{TEST_DIR}}/`
- Docs: `docs/`

## Quick Commands

- `/tdd` — Test-driven development
- `/code-review` — Review changes
- `/plan` — Plan before building
- `/commit-by-feature` — Clean commit history

<!-- managed by claude-code-starter -->
# Testing Requirements

## Minimum Test Coverage: {{COVERAGE_THRESHOLD}}%

Test types (ALL required for new features):
1. **Unit Tests** — Individual functions, utilities, model methods
2. **Integration Tests** — API endpoints, DB operations
3. **E2E Tests** — Critical user flows

## Test-Driven Development

MANDATORY workflow for new features and bug fixes:
1. Write test first (RED)
2. Run test — it should FAIL (`{{TEST_CMD}} {{TEST_DIR}}/test_new_feature.py -x`)
3. Write minimal implementation (GREEN)
4. Run test — it should PASS
5. Refactor (IMPROVE)
6. Verify coverage: `{{COVERAGE_CMD}}`

## Test Organization

```
{{TEST_DIR}}/
  conftest.py              # Shared fixtures, DB session, factories
  test_*.py                # Unit tests (parallel to source modules)
  integration/             # Multi-component integration tests
```

## TDD for Security-Critical Code

Use TDD proactively for:
- Token-based authentication/authorization
- Database mutations requiring change tracking
- Race condition prevention (locking)
- Input validation (prevent injection)
- Idempotency (prevent duplicate actions)

## Troubleshooting Test Failures

1. Read the full error traceback
2. Check test isolation (shared state leaking between tests)
3. Verify fixtures provide clean state
4. Fix implementation, not tests (unless tests are wrong)
5. For flaky tests: check for ordering dependencies, missing flushes

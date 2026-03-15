<!-- managed by claude-code-starter -->
---
description: Check test coverage and generate tests for untested paths
---

# Test Coverage

## Steps

1. **Run coverage report**:
   ```bash
   {{COVERAGE_CMD}}
   ```
2. **Identify uncovered paths** — focus on files changed this session
3. **Generate tests** for critical uncovered paths
4. **Re-run coverage** to verify improvement
5. **Target**: {{COVERAGE_THRESHOLD}}%+ for all new code

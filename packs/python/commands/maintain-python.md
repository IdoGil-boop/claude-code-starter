<!-- managed by claude-code-starter [pack:python] -->
# /maintain — Python Extras

Additional post-session checks for Python projects (loaded alongside base maintain.md):

- **Lint check**: Run `{{LINT_CMD}} {{SOURCE_DIR}}/` — flag if new violations were introduced this session
- **Type check**: Run `{{TYPE_CHECK_CMD}} {{SOURCE_DIR}}/` — flag if new type errors were introduced
- **Requirements sync**: If new imports were added, verify they're in requirements.txt/pyproject.toml
- **Security scan**: Run `{{SECURITY_CMD}} {{SOURCE_DIR}}/` for new security issues

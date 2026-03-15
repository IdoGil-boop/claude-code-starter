<!-- managed by claude-code-starter [pack:python] -->
---
name: python-testing
description: Python testing strategies using pytest, TDD methodology, fixtures, mocking, and coverage.
---

# Python Testing

## pytest Patterns

### Fixtures
```python
@pytest.fixture
def db_session():
    """Transactional session that rolls back after each test."""

@pytest.fixture
def sample_item(db_session):
    """Create test item with defaults."""
```

### Mocking
```python
from unittest.mock import MagicMock, patch

@patch("app.service.external_call")
def test_with_mock(mock_call):
    mock_call.return_value = {"status": "ok"}
    result = process()
    mock_call.assert_called_once()
```

### Parametrize
```python
@pytest.mark.parametrize("input,expected", [
    (None, False),
    ("", False),
    ("valid", True),
])
def test_validate(input, expected):
    assert validate(input) == expected
```

### JSONB Mutation Testing
```python
def test_jsonb_persists(db_session):
    obj = create_obj(db_session)
    obj.data.append({"key": "value"})
    flag_modified(obj, "data")
    db_session.commit()
    db_session.expire_all()
    assert obj.data[-1]["key"] == "value"
```

## Coverage
```bash
{{COVERAGE_CMD}}
# Target: {{COVERAGE_THRESHOLD}}%+
```

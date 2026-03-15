<!-- managed by claude-code-starter [pack:python] -->
---
name: python-patterns
description: Pythonic idioms, PEP 8 standards, type hints, and best practices.
---

# Python Patterns

## Pythonic Idioms

- List/dict/set comprehensions over `map()`/`filter()`
- `with` statements for resource management
- `enumerate()` over manual index tracking
- `zip()` for parallel iteration
- Walrus operator `:=` for assignment in conditions (Python 3.8+)
- `|` for dict merge (Python 3.9+), `X | Y` for type unions (3.10+)

## Type Hints

```python
from __future__ import annotations
from typing import Any

def process(items: list[Item], *, config: Config | None = None) -> Result: ...
```

## Error Handling

```python
# Specific exceptions with context
raise ValueError(f"Invalid {field}: {value!r}")

# Log and re-raise
try:
    result = external_call()
except SpecificError as exc:
    logger.error("Call failed", exc_info=exc, extra={"id": id})
    raise
```

## Testing with pytest

```python
import pytest

@pytest.fixture
def sample_data():
    return {"key": "value"}

@pytest.mark.parametrize("input,expected", [
    (0, "zero"),
    (1, "one"),
])
def test_classify(input, expected):
    assert classify(input) == expected
```

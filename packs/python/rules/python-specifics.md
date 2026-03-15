<!-- managed by claude-code-starter [pack:python] -->
# Python-Specific Rules

## PEP 8 Naming
- `snake_case` for functions, variables, module names
- `PascalCase` for classes, exceptions
- `UPPER_SNAKE_CASE` for constants
- `_leading_underscore` for private members

## Type Hints (Mandatory)
```python
def process_items(
    db: Session,
    items: list[Item],
    *,
    limit: int | None = None,
) -> list[Result]:
```

## Immutability
- Use `@dataclass(frozen=True)` for value objects
- Use `NamedTuple` for lightweight records
- Exception: ORM models (use `flag_modified()` for JSONB)

## Logging
```python
import logging
logger = logging.getLogger(__name__)

# GOOD: Structured with context
logger.info("Operation complete", extra={"account_id": id, "count": n})

# BAD: print() in production
print(f"Done for {id}")
```

## SQLAlchemy Patterns

### JSONB Mutations (CRITICAL)
```python
from sqlalchemy.orm.attributes import flag_modified
obj.json_col.append(item)
flag_modified(obj, "json_col")  # Without this, change is silently lost
db.commit()
```

### Boolean Filters
```python
# CORRECT
query.filter(Model.active.is_(True))
query.filter(Model.deleted_at.is_(None))

# WRONG (Ruff E712/E711)
query.filter(Model.active == True)
```

### N+1 Prevention
```python
from sqlalchemy.orm import joinedload
db.query(Parent).options(joinedload(Parent.children)).all()
```

### Row Locking
```python
row = db.query(Model).filter_by(id=id).with_for_update().first()
```

## Celery Tasks
- JSON serializer only (never pickle)
- Pass IDs, not ORM objects
- Validate arguments at task start
- Use `acks_late=True` for critical tasks

## Tools
```bash
ruff check {{SOURCE_DIR}}/     # Lint
mypy {{SOURCE_DIR}}/           # Type check
bandit -r {{SOURCE_DIR}}/      # Security scan
pip-audit                       # Dependency audit
```

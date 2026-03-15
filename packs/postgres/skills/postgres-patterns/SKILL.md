<!-- managed by claude-code-starter [pack:postgres] -->
---
name: postgres-patterns
description: PostgreSQL patterns for query optimization, schema design, indexing, and security.
---

# PostgreSQL Patterns

## Indexing
- B-tree for equality/range (default)
- GIN for JSONB containment (`@>`) and array (`&&`)
- Partial indexes for filtered queries (`WHERE active = true`)
- Composite indexes: leftmost column must match filter

## JSONB
- `->` returns JSON, `->>` returns text
- `@>` for containment queries (GIN indexable)
- `jsonb_set()` for updates
- In ORM: always `flag_modified()` after in-place mutation

## Upsert
```sql
INSERT INTO table (id, data)
VALUES (1, 'value')
ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data;
```

## Row Locking
```sql
SELECT * FROM table WHERE id = 1 FOR UPDATE;
-- Or in ORM: .with_for_update()
```

## Migration Best Practices
- Always test `upgrade` AND `downgrade`
- Use `server_default` for new NOT NULL columns
- Create indexes CONCURRENTLY for large tables
- Never modify applied migrations

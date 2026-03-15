<!-- managed by claude-code-starter [pack:postgres] -->
# /maintain — PostgreSQL Extras

Additional post-session checks for PostgreSQL projects (loaded alongside base maintain.md):

- **DB Schema Sync**: If model files changed this session, regenerate schema reference documentation
- **Migration check**: Verify migration chain is clean (test both upgrade and downgrade on fresh DB)
- **Index review**: Check if new filter/order columns need indexes

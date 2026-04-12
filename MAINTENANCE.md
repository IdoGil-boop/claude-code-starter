# Maintaining claude-code-starter

How to evolve this kit: add skills, bump existing ones, decide between base and packs, and push changes upstream.

## Directory Layout

```
.claude-starter/
├── base/                    # Universal files — applied to every project
│   ├── .claude/
│   │   ├── skills/<name>/SKILL.md
│   │   ├── agents/<name>.md
│   │   ├── rules/<name>.md
│   │   ├── commands/<name>.md
│   │   ├── contexts/<name>.md
│   │   └── hooks/*.py
│   └── docs/
├── packs/                   # Stack-specific extensions (opt-in via starter.config.yaml)
│   ├── python/              # Python: pytest skills, python-reviewer agent, lint steps
│   ├── postgres/            # Postgres: schema review agent, patterns skill
│   └── nextjs/              # Next.js: E2E runner, frontend patterns
├── settings/                # Shared settings.json fragments
└── install.sh               # Sync engine — diff, install, update
```

## Adding a New Item

### Decide: base or pack?

| Put in `base/` if... | Put in `packs/<lang>/` if... |
|----------------------|------------------------------|
| Works for any language/stack | Depends on a specific language or framework |
| No assumption about build tools | Mentions `pytest`, `pnpm`, `alembic`, etc. |
| Describes a workflow (commit, deploy, debug) | Describes code patterns for one ecosystem |
| Example: `/commit-by-feature`, `/deploy-after-merge` | Example: `python-testing`, `postgres-patterns` |

### Add a Skill

1. Create the directory and file:
   ```
   base/.claude/skills/<skill-name>/SKILL.md
   ```
2. First line MUST be the management header:
   ```markdown
   <!-- managed by claude-code-starter -->
   ---
   name: <skill-name>
   description: <one-line description — shown in the skill picker>
   ---
   ```
3. Use `{{PLACEHOLDER}}` syntax for values that differ per project (see Templates below).
4. If it's a first-run template (needs project-specific values filled in), add a "First-Run Setup" section that explains what to discover from the repo and what to ask the user.

### Add an Agent, Rule, Command, Hook

Same rules: file goes in the matching `base/.claude/<type>/` directory, starts with the management header, uses placeholders.

## Template Placeholders

When files need to differ per project, use double-brace placeholders. The installer substitutes them from `starter.config.yaml`:

| Placeholder | Typical value |
|-------------|---------------|
| `{{PROJECT_NAME}}` | `lawyer_app`, `blossomads` |
| `{{TEST_CMD}}` | `pytest`, `vitest`, `jest` |
| `{{TEST_DIR}}` | `backend/tests`, `test`, `__tests__` |
| `{{LINT_CMD}}` | `ruff check .`, `pnpm lint` |
| `{{TYPE_CHECK_CMD}}` | `mypy app/`, `tsc --noEmit` |
| `{{COVERAGE_CMD}}` | `pytest --cov=app` |
| `{{COVERAGE_THRESHOLD}}` | `80` |

Check existing files (`base/.claude/rules/testing.md`) for the full list of recognized placeholders.

## Testing a Change Locally

Before committing to the starter, test your change in a real project:

```bash
# From a consuming project (e.g., lawyer_app)
cd .claude-starter
git checkout -b my-change
# ...edit files in base/ or packs/...
cd ..
./.claude-starter/install.sh --diff    # preview what changes
./.claude-starter/install.sh --sync    # apply
# Use the new skill / agent / rule in a real task
```

If it works, commit and push upstream:

```bash
cd .claude-starter
git add -A
git commit -m "feat: add /my-skill"
git push origin my-change
# Open PR against claude-code-starter main
```

## Sync Behavior Rules

| File type | How to mark it | Sync behavior |
|-----------|----------------|---------------|
| **Starter-managed** | `<!-- managed by claude-code-starter -->` at top | Overwritten on `--sync` |
| **Project-local** | No header, or `-local` suffix in filename | Never touched by sync |
| **Template-seeded** | `.template` extension in source | Created once, never overwritten |

The installer diffs managed files hash-by-hash against what's in the starter. If a project edits a managed file without removing the header, the edit is lost on next sync — **push the edit upstream first**.

## Upstream Sync Workflow

The `/upstream-sync` skill automates pushing local improvements back to the starter:

1. Claude identifies what changed locally in a managed file
2. Copies the change into `.claude-starter/base/...`
3. Commits in `.claude-starter/` and pushes to origin
4. Runs `install.sh --sync` to restore parity

Only universal improvements go upstream. Project-specific content stays in a `-local` variant (e.g., `rules/coding-style-local.md`).

## When to Bump vs Create New

- **Bump existing** if the change generalizes or improves current behavior
- **Create new** if the workflow is genuinely different, or if the old version still serves projects that haven't adopted the new pattern
- **Never delete without deprecation** — other projects pull from `main`; breaking changes need a rename or a version bump documented in the commit message

## First-Run Template Pattern

For skills that need project-specific values on first use (like `/deploy-after-merge`), follow this pattern:

1. Ship the skill with placeholders AND a "First-Run Setup" section
2. The setup section tells Claude what to discover from the repo (docker-compose files, scripts/, etc.) and what to ask the user
3. After discovery, Claude writes the populated values **inline into the same SKILL.md** in the consuming project
4. Subsequent runs skip the setup — the skill is now project-specific
5. Because the populated file still has the management header, running `install.sh --sync` would overwrite it. To prevent this, the installer treats files with populated placeholders as local. (Alternatively, document that users should remove the management header after first setup.)

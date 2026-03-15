# claude-code-starter

Reusable Claude Code setup kit: agents, skills, hooks, rules, commands, contexts, instinct learning, memory system, and `/maintain` workflow.

Import into any project. Keep in sync via `install.sh`.

## Quick Start (One Command)

```bash
# In your project root:
bash <(curl -fsSL https://raw.githubusercontent.com/IdoGil-boop/claude-code-starter/main/setup.sh)
```

Auto-detects your stack, creates config, installs everything, updates `.gitignore`. Done.

Options via env vars:
```bash
# Skip the config review pause (use auto-detected defaults):
SKIP_EDIT=1 bash <(curl -fsSL https://raw.githubusercontent.com/IdoGil-boop/claude-code-starter/main/setup.sh)

# Override project name:
PROJECT_NAME=my-app bash <(curl -fsSL https://raw.githubusercontent.com/IdoGil-boop/claude-code-starter/main/setup.sh)
```

<details>
<summary>Manual setup (4 steps)</summary>

```bash
git clone --depth 1 https://github.com/IdoGil-boop/claude-code-starter.git .claude-starter
cp .claude-starter/starter.config.yaml.example starter.config.yaml
# Edit starter.config.yaml with your project details
.claude-starter/install.sh
echo ".claude-starter/" >> .gitignore
```
</details>

## Commands

```bash
# First install (auto-detects stack if no config exists):
.claude-starter/install.sh

# Sync with latest starter (updates managed files, preserves local):
.claude-starter/install.sh --sync

# Preview what would change:
.claude-starter/install.sh --diff

# Force re-initialize (overwrites templates too):
.claude-starter/install.sh --init --force
```

## File Ownership

| Type | Convention | Sync behavior |
|------|-----------|---------------|
| **Starter-managed** | Has `<!-- managed by claude-code-starter -->` header | Overwritten on `--sync` |
| **Project-local** | No header, or `-local` suffix | Never touched by sync |
| **Template-seeded** | `.template` source, no header in output | Created once, never overwritten |

## Layered Files

Claude Code loads ALL `.md` files in `rules/`, `contexts/`, etc. This enables composable overrides:

- Starter provides `rules/coding-style.md` (generic)
- You add `rules/coding-style-local.md` (project-specific)
- Both are loaded automatically

## Packs

Optional language/stack extensions:

| Pack | Adds |
|------|------|
| `python` | Python-specific rules, reviewer agent, pytest skills, `/maintain` lint step |
| `postgres` | Database reviewer agent, PostgreSQL patterns skill, `/maintain` schema sync step |
| `nextjs` | E2E runner agent, frontend patterns skill, `/maintain` route health check |

Configure in `starter.config.yaml`:
```yaml
packs:
  - python
  - postgres
```

## cc10x Integration

When `enable_cc10x: true` in config:
- Adds cc10x plugin to settings.json
- Installs cc10x hooks and codex-patch skill
- Creates `.claude/cc10x/` memory directory
- References cc10x router in orchestrator

## Documentation Architecture

The starter enforces a CLAUDE.md-as-index pattern:

```
CLAUDE.md (≤120 lines)         ← Index + overview. Never inline details.
  ├── docs/INDEX.md             ← Master doc index
  ├── docs/architecture/*.md    ← System design
  ├── docs/reference/*.md       ← Gotchas, models, ops
  ├── docs/guides/*.md          ← How-to guides
  └── docs/plans/*.md           ← Implementation plans
```

## Upstream Sync — Push Learnings Back

When you discover a universal gotcha or improve a rule/skill/agent in a project, push it back to the starter so all projects benefit:

The `upstream-sync` skill guides Claude through this — it edits files in `.claude-starter/`, commits, and pushes to origin. Then re-syncs the local project.

Only universal learnings go upstream. Project-specific content stays in `-local` files.

## Updating

```bash
cd .claude-starter && git pull && cd ..
.claude-starter/install.sh --sync
```

Managed files are updated. Local files are untouched. Templates are never overwritten.

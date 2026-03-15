#!/usr/bin/env bash
set -euo pipefail

# claude-code-starter install/sync script
# Usage: install.sh [--init | --sync | --diff] [--force]

STARTER_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"
CONFIG_FILE="$PROJECT_DIR/starter.config.yaml"
MANAGED_HEADER="<!-- managed by claude-code-starter -->"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
CREATED=0
UPDATED=0
SKIPPED=0
SEEDED=0

# --- Helpers ---

log_info()  { echo -e "${BLUE}[info]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[ok]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
log_err()   { echo -e "${RED}[error]${NC} $1"; }

# Parse YAML value (simple key: value, no nested support)
yaml_val() {
  local key="$1" file="$2"
  grep "^${key}:" "$file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//"
}

# Parse YAML list items (lines starting with "  - ")
yaml_list() {
  local key="$1" file="$2"
  awk "/^${key}:/{found=1; next} found && /^  - /{print \$2} found && /^[^ ]/{found=0}" "$file"
}

# Template variable substitution
substitute_vars() {
  local content="$1"
  content="${content//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
  content="${content//\{\{PROJECT_DESCRIPTION\}\}/$PROJECT_DESCRIPTION}"
  content="${content//\{\{TECH_STACK\}\}/$TECH_STACK}"
  content="${content//\{\{BACKEND_DIR\}\}/$BACKEND_DIR}"
  content="${content//\{\{FRONTEND_DIR\}\}/$FRONTEND_DIR}"
  content="${content//\{\{SOURCE_DIR\}\}/$SOURCE_DIR}"
  content="${content//\{\{TEST_DIR\}\}/$TEST_DIR}"
  content="${content//\{\{MIGRATION_DIR\}\}/$MIGRATION_DIR}"
  content="${content//\{\{TEST_CMD\}\}/$TEST_CMD}"
  content="${content//\{\{LINT_CMD\}\}/$LINT_CMD}"
  content="${content//\{\{TYPE_CHECK_CMD\}\}/$TYPE_CHECK_CMD}"
  content="${content//\{\{SECURITY_CMD\}\}/$SECURITY_CMD}"
  content="${content//\{\{COVERAGE_CMD\}\}/$COVERAGE_CMD}"
  content="${content//\{\{FRONTEND_TYPE_CHECK_CMD\}\}/$FRONTEND_TYPE_CHECK_CMD}"
  content="${content//\{\{COVERAGE_THRESHOLD\}\}/$COVERAGE_THRESHOLD}"
  echo "$content"
}

# Check if file has managed header
is_managed() {
  head -3 "$1" 2>/dev/null | grep -qF "managed by claude-code-starter"
}

# Copy file with template substitution
copy_with_sub() {
  local src="$1" dst="$2"
  local content
  content="$(cat "$src")"
  content="$(substitute_vars "$content")"
  mkdir -p "$(dirname "$dst")"
  echo "$content" > "$dst"
}

# Install a managed file (overwrite if managed, skip if local)
install_managed() {
  local src="$1" dst="$2" pack_tag="${3:-}"

  if [[ -f "$dst" ]]; then
    if is_managed "$dst"; then
      # Backup and overwrite
      cp "$dst" "${dst}.bak"
      copy_with_sub "$src" "$dst"
      ((UPDATED++)) || true
    else
      # Project-local — skip
      ((SKIPPED++)) || true
    fi
  else
    # New file
    copy_with_sub "$src" "$dst"
    ((CREATED++)) || true
  fi
}

# Install a template file (create once, never overwrite)
install_template() {
  local src="$1" dst="$2"

  if [[ -f "$dst" ]]; then
    ((SKIPPED++)) || true
  else
    copy_with_sub "$src" "$dst"
    ((SEEDED++)) || true
  fi
}

# --- Stack Auto-Detection ---

auto_detect_stack() {
  log_info "No starter.config.yaml found. Auto-detecting stack..."

  local detected_packs=()
  local detected_stack=""
  local detected_backend="backend"
  local detected_frontend="frontend"
  local detected_source="backend/app"
  local detected_test="backend/tests"
  local detected_migration="backend/alembic/versions"
  local detected_test_cmd="pytest"
  local detected_lint_cmd="ruff check"
  local detected_type_check="mypy"
  local detected_security="bandit -r"
  local detected_coverage="pytest --cov=app --cov-report=term-missing"
  local detected_fe_type_check="npx tsc --noEmit"

  # Python detection
  if [[ -f "$PROJECT_DIR/pyproject.toml" ]] || [[ -f "$PROJECT_DIR/requirements.txt" ]] || [[ -f "$PROJECT_DIR/backend/requirements.txt" ]]; then
    detected_packs+=("python")
    detected_stack="Python"

    # Check for FastAPI
    if grep -rq "fastapi" "$PROJECT_DIR/pyproject.toml" "$PROJECT_DIR/requirements.txt" "$PROJECT_DIR/backend/requirements.txt" 2>/dev/null; then
      detected_stack="Python + FastAPI"
    fi

    # Detect source dir
    if [[ -d "$PROJECT_DIR/src" ]]; then
      detected_source="src"
      detected_test="tests"
      detected_backend="."
    elif [[ -d "$PROJECT_DIR/app" ]]; then
      detected_source="app"
      detected_test="tests"
      detected_backend="."
    fi
  fi

  # Node.js / Next.js detection
  if [[ -f "$PROJECT_DIR/package.json" ]] || [[ -f "$PROJECT_DIR/frontend/package.json" ]]; then
    local pkg_file="$PROJECT_DIR/package.json"
    [[ -f "$PROJECT_DIR/frontend/package.json" ]] && pkg_file="$PROJECT_DIR/frontend/package.json"

    if grep -q '"next"' "$pkg_file" 2>/dev/null; then
      detected_packs+=("nextjs")
      detected_stack="${detected_stack:+$detected_stack + }Next.js"
    fi
  fi

  # PostgreSQL detection
  if grep -rq "postgres" "$PROJECT_DIR/docker-compose.yml" "$PROJECT_DIR/docker-compose.yaml" 2>/dev/null || \
     grep -rq "psycopg\|asyncpg\|sqlalchemy" "$PROJECT_DIR/pyproject.toml" "$PROJECT_DIR/requirements.txt" "$PROJECT_DIR/backend/requirements.txt" 2>/dev/null; then
    detected_packs+=("postgres")
    detected_stack="${detected_stack:+$detected_stack + }PostgreSQL"
  fi

  [[ -z "$detected_stack" ]] && detected_stack="General"

  local packs_yaml=""
  if [[ ${#detected_packs[@]} -gt 0 ]]; then
    for pack in "${detected_packs[@]}"; do
      packs_yaml="$packs_yaml\n  - $pack"
    done
  fi

  local project_name
  project_name="$(basename "$PROJECT_DIR")"

  log_info "Detected: $detected_stack"
  log_info "Packs: ${detected_packs[*]:-none}"

  cat > "$CONFIG_FILE" << YAML
# claude-code-starter configuration (auto-detected)
starter_repo: "https://github.com/IdoGil-boop/claude-code-starter.git"
starter_version: "v1.0.0"

project_name: "$project_name"
project_description: ""
tech_stack: "$detected_stack"

backend_dir: "$detected_backend"
frontend_dir: "$detected_frontend"
source_dir: "$detected_source"
test_dir: "$detected_test"
migration_dir: "$detected_migration"

test_cmd: "$detected_test_cmd"
lint_cmd: "$detected_lint_cmd"
type_check_cmd: "$detected_type_check"
security_cmd: "$detected_security"
coverage_cmd: "$detected_coverage"
frontend_type_check_cmd: "$detected_fe_type_check"
coverage_threshold: 80

packs:$(echo -e "$packs_yaml")

enable_cc10x: true
YAML

  log_ok "Created starter.config.yaml with detected settings"
  log_warn "Review and edit starter.config.yaml, then re-run install.sh"
}

# --- Load Config ---

load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    auto_detect_stack
    exit 0
  fi

  PROJECT_NAME="$(yaml_val "project_name" "$CONFIG_FILE")"
  PROJECT_DESCRIPTION="$(yaml_val "project_description" "$CONFIG_FILE")"
  TECH_STACK="$(yaml_val "tech_stack" "$CONFIG_FILE")"
  BACKEND_DIR="$(yaml_val "backend_dir" "$CONFIG_FILE")"
  FRONTEND_DIR="$(yaml_val "frontend_dir" "$CONFIG_FILE")"
  SOURCE_DIR="$(yaml_val "source_dir" "$CONFIG_FILE")"
  TEST_DIR="$(yaml_val "test_dir" "$CONFIG_FILE")"
  MIGRATION_DIR="$(yaml_val "migration_dir" "$CONFIG_FILE")"
  TEST_CMD="$(yaml_val "test_cmd" "$CONFIG_FILE")"
  LINT_CMD="$(yaml_val "lint_cmd" "$CONFIG_FILE")"
  TYPE_CHECK_CMD="$(yaml_val "type_check_cmd" "$CONFIG_FILE")"
  SECURITY_CMD="$(yaml_val "security_cmd" "$CONFIG_FILE")"
  COVERAGE_CMD="$(yaml_val "coverage_cmd" "$CONFIG_FILE")"
  FRONTEND_TYPE_CHECK_CMD="$(yaml_val "frontend_type_check_cmd" "$CONFIG_FILE")"
  COVERAGE_THRESHOLD="$(yaml_val "coverage_threshold" "$CONFIG_FILE")"
  ENABLE_CC10X="$(yaml_val "enable_cc10x" "$CONFIG_FILE")"

  # Defaults
  PROJECT_NAME="${PROJECT_NAME:-$(basename "$PROJECT_DIR")}"
  TECH_STACK="${TECH_STACK:-General}"
  BACKEND_DIR="${BACKEND_DIR:-backend}"
  FRONTEND_DIR="${FRONTEND_DIR:-frontend}"
  SOURCE_DIR="${SOURCE_DIR:-src}"
  TEST_DIR="${TEST_DIR:-tests}"
  TEST_CMD="${TEST_CMD:-pytest}"
  LINT_CMD="${LINT_CMD:-ruff check}"
  COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
  ENABLE_CC10X="${ENABLE_CC10X:-true}"
}

# --- settings.json Merge ---

merge_settings() {
  local project_settings="$PROJECT_DIR/.claude/settings.json"
  local starter_hooks="$STARTER_DIR/settings/hooks.json"

  [[ ! -f "$starter_hooks" ]] && return

  if [[ ! -f "$project_settings" ]]; then
    mkdir -p "$PROJECT_DIR/.claude"
    cp "$starter_hooks" "$project_settings"
    log_ok "Created .claude/settings.json from starter hooks"
    return
  fi

  # Backup existing
  cp "$project_settings" "${project_settings}.bak"

  # Use python for JSON merge (available on macOS/Linux)
  python3 << PYEOF
import json, sys

with open("$project_settings") as f:
    project = json.load(f)
with open("$starter_hooks") as f:
    starter = json.load(f)

# Merge hooks (additive — never remove existing)
for event, hooks in starter.get("hooks", {}).items():
    if event not in project.setdefault("hooks", {}):
        project["hooks"][event] = []
    existing_cmds = {h.get("command", "") for h in project["hooks"][event]}
    for hook in hooks:
        if hook.get("command", "") not in existing_cmds:
            project["hooks"][event].append(hook)

# Merge enabledPlugins (additive)
for plugin, enabled in starter.get("enabledPlugins", {}).items():
    project.setdefault("enabledPlugins", {})[plugin] = enabled

with open("$project_settings", "w") as f:
    json.dump(project, f, indent=2)
    f.write("\n")
PYEOF

  log_ok "Merged hooks into .claude/settings.json"
}

# --- Install Base Files ---

install_base() {
  log_info "Installing base files..."

  local base_dir="$STARTER_DIR/base"

  # Walk all files in base/
  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$base_dir/}"
    local dst_file="$PROJECT_DIR/$rel_path"

    # .template files → seed once (strip .template extension)
    if [[ "$src_file" == *.template ]]; then
      local dst_no_ext="${dst_file%.template}"
      install_template "$src_file" "$dst_no_ext"
    else
      install_managed "$src_file" "$dst_file"
    fi
  done < <(find "$base_dir" -type f -print0)

  # Create directory structure
  mkdir -p "$PROJECT_DIR/docs/architecture" \
           "$PROJECT_DIR/docs/reference" \
           "$PROJECT_DIR/docs/guides" \
           "$PROJECT_DIR/docs/plans" \
           "$PROJECT_DIR/.claude/instincts/personal" \
           "$PROJECT_DIR/.claude/instincts/inherited" \
           "$PROJECT_DIR/.claude/instincts/evolved/agents" \
           "$PROJECT_DIR/.claude/instincts/evolved/skills" \
           "$PROJECT_DIR/.claude/instincts/evolved/commands"

  # Create .gitkeep files for empty dirs
  for dir in docs/architecture docs/reference docs/guides docs/plans \
             .claude/instincts/personal .claude/instincts/inherited \
             .claude/instincts/evolved/agents .claude/instincts/evolved/skills \
             .claude/instincts/evolved/commands; do
    touch "$PROJECT_DIR/$dir/.gitkeep"
  done
}

# --- Install Packs ---

install_packs() {
  local packs
  packs="$(yaml_list "packs" "$CONFIG_FILE")"

  [[ -z "$packs" ]] && return

  for pack in $packs; do
    local pack_dir="$STARTER_DIR/packs/$pack"
    if [[ ! -d "$pack_dir" ]]; then
      log_warn "Pack '$pack' not found, skipping"
      continue
    fi

    log_info "Installing pack: $pack"

    while IFS= read -r -d '' src_file; do
      local rel_path="${src_file#$pack_dir/}"
      local dst_file="$PROJECT_DIR/.claude/$rel_path"

      # Skills go into .claude/skills/, agents into .claude/agents/, etc.
      install_managed "$src_file" "$dst_file" "$pack"
    done < <(find "$pack_dir" -type f -print0)
  done
}

# --- cc10x Integration ---

install_cc10x() {
  if [[ "$ENABLE_CC10X" != "true" ]]; then
    return
  fi

  log_info "Installing cc10x integration..."

  # Create cc10x memory directory
  mkdir -p "$PROJECT_DIR/.claude/cc10x"

  # cc10x codex-patch skill
  local cc10x_skill_dir="$STARTER_DIR/base/.claude/skills/cc10x-codex-patch"
  if [[ -d "$cc10x_skill_dir" ]]; then
    mkdir -p "$PROJECT_DIR/.claude/skills/cc10x-codex-patch"
    while IFS= read -r -d '' src_file; do
      local rel_path="${src_file#$cc10x_skill_dir/}"
      install_managed "$src_file" "$PROJECT_DIR/.claude/skills/cc10x-codex-patch/$rel_path"
    done < <(find "$cc10x_skill_dir" -type f -print0)
  fi
}

# --- Cleanup Old Backups ---

cleanup_backups() {
  find "$PROJECT_DIR/.claude" -name "*.bak" -mtime +7 -delete 2>/dev/null || true
  find "$PROJECT_DIR/docs" -name "*.bak" -mtime +7 -delete 2>/dev/null || true
}

# --- Diff Mode ---

do_diff() {
  load_config
  log_info "Comparing starter files vs installed files..."

  local base_dir="$STARTER_DIR/base"
  local outdated=0 new_files=0 modified=0

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$base_dir/}"
    local dst_file="$PROJECT_DIR/$rel_path"

    if [[ "$src_file" == *.template ]]; then
      dst_file="${dst_file%.template}"
      if [[ ! -f "$dst_file" ]]; then
        echo -e "  ${GREEN}NEW (template)${NC}: $rel_path"
        ((new_files++)) || true
      fi
    elif [[ ! -f "$dst_file" ]]; then
      echo -e "  ${GREEN}NEW${NC}: $rel_path"
      ((new_files++)) || true
    elif is_managed "$dst_file"; then
      local src_content dst_content
      src_content="$(substitute_vars "$(cat "$src_file")")"
      dst_content="$(cat "$dst_file")"
      if [[ "$src_content" != "$dst_content" ]]; then
        echo -e "  ${YELLOW}OUTDATED${NC}: $rel_path"
        ((outdated++)) || true
      fi
    else
      echo -e "  ${BLUE}LOCAL${NC}: $rel_path (project-owned, won't touch)"
      ((modified++)) || true
    fi
  done < <(find "$base_dir" -type f -print0)

  echo ""
  log_info "Summary: $new_files new, $outdated outdated, $modified local"
}

# --- Main ---

MODE=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --init)  MODE="init"; shift ;;
    --sync)  MODE="sync"; shift ;;
    --diff)  MODE="diff"; shift ;;
    --force) FORCE=true; shift ;;
    *)       log_err "Unknown option: $1"; exit 1 ;;
  esac
done

# Default mode
if [[ -z "$MODE" ]]; then
  if [[ -d "$PROJECT_DIR/.claude" ]]; then
    MODE="sync"
  else
    MODE="init"
  fi
fi

case "$MODE" in
  diff)
    do_diff
    ;;
  init|sync)
    load_config
    log_info "Running --${MODE} for $PROJECT_NAME ($TECH_STACK)"
    echo ""

    install_base
    install_packs
    install_cc10x
    merge_settings
    cleanup_backups

    echo ""
    log_ok "Done! Created: $CREATED, Updated: $UPDATED, Seeded: $SEEDED, Skipped: $SKIPPED"

    if [[ $SEEDED -gt 0 ]]; then
      echo ""
      log_info "Template files were seeded. Review and customize:"
      log_info "  - CLAUDE.md"
      log_info "  - docs/INDEX.md"
      log_info "  - memory/MEMORY.md"
    fi
    ;;
esac

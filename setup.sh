#!/usr/bin/env bash
set -euo pipefail

# claude-code-starter — one-command setup
# Usage: curl -fsSL https://raw.githubusercontent.com/IdoGil-boop/claude-code-starter/main/setup.sh | bash
#    or: bash <(curl -fsSL https://raw.githubusercontent.com/IdoGil-boop/claude-code-starter/main/setup.sh)
#
# Options (passed as env vars):
#   STARTER_BRANCH=main          Git branch to clone (default: main)
#   SKIP_EDIT=1                  Skip the "edit config" pause (use auto-detected or default config)
#   PROJECT_NAME=my-app          Override project name (default: directory name)

REPO_URL="https://github.com/IdoGil-boop/claude-code-starter.git"
BRANCH="${STARTER_BRANCH:-main}"
STARTER_DIR=".claude-starter"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[starter]${NC} $1"; }
ok()    { echo -e "${GREEN}[starter]${NC} $1"; }
warn()  { echo -e "${YELLOW}[starter]${NC} $1"; }
err()   { echo -e "${RED}[starter]${NC} $1"; }

# --- Preflight ---

if ! command -v git &>/dev/null; then
  err "git is required. Install it and re-run."
  exit 1
fi

if [[ -d "$STARTER_DIR" ]]; then
  info "Existing .claude-starter/ found — pulling latest..."
  (cd "$STARTER_DIR" && git pull --rebase origin "$BRANCH" 2>/dev/null) || true
else
  info "Cloning claude-code-starter..."
  git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$STARTER_DIR"
fi

# --- Config ---

if [[ ! -f "starter.config.yaml" ]]; then
  info "No config found — running auto-detection..."
  "$STARTER_DIR/install.sh" --init

  # install.sh auto-detect creates config and exits. Now we need to
  # optionally let the user review it, then proceed to the actual install.
  if [[ -f "starter.config.yaml" ]]; then
    if [[ "${SKIP_EDIT:-0}" == "1" ]]; then
      info "SKIP_EDIT=1 — using auto-detected config as-is"
    else
      # Apply PROJECT_NAME override if provided
      if [[ -n "${PROJECT_NAME:-}" ]]; then
        if command -v sed &>/dev/null; then
          sed -i.bak "s/^project_name:.*/project_name: \"$PROJECT_NAME\"/" starter.config.yaml
          rm -f starter.config.yaml.bak
          info "Set project_name to: $PROJECT_NAME"
        fi
      fi

      echo ""
      warn "Review starter.config.yaml before continuing."
      warn "Press Enter to continue with current config, or Ctrl+C to edit first."
      read -r
    fi
  fi
fi

# --- Install ---

info "Installing starter files..."
"$STARTER_DIR/install.sh"

# --- Gitignore ---

if [[ -f ".gitignore" ]]; then
  if ! grep -q "^\.claude-starter/" .gitignore 2>/dev/null; then
    echo ".claude-starter/" >> .gitignore
    info "Added .claude-starter/ to .gitignore"
  fi
else
  echo ".claude-starter/" > .gitignore
  info "Created .gitignore with .claude-starter/"
fi

# Ignore the config too (contains project-specific paths, not starter-managed)
if ! grep -q "^starter\.config\.yaml" .gitignore 2>/dev/null; then
  echo "starter.config.yaml" >> .gitignore
  info "Added starter.config.yaml to .gitignore"
fi

echo ""
ok "claude-code-starter is installed!"
echo ""
info "What's next:"
info "  1. Review and customize CLAUDE.md"
info "  2. Review .claude/settings.json hooks"
info "  3. Start coding with Claude Code"
echo ""
info "To update later:  .claude-starter/install.sh --sync"
info "To preview changes: .claude-starter/install.sh --diff"

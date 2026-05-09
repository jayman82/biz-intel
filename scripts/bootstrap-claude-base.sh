#!/usr/bin/env bash
# bootstrap-claude-base.sh — set up the shared toolbox for this repo.
#
# What it does:
#   1. Detects whether ~/repo/claude-base (or $CLAUDE_BASE_DIR) exists.
#   2. Clones claude-base if missing; pulls latest if present.
#   3. Runs claude-base/setup.py to link the right set of skills into
#      this repo's .claude/skills/ directory.
#
# Why this exists:
#   biz-* repos consume shared skills + presentations engine code from
#   claude-base via symlinks. Teammates who clone a biz-* repo without
#   already having claude-base end up with dangling symlinks. This
#   script makes the dependency self-installing.
#
# Usage:
#   ./scripts/bootstrap-claude-base.sh
#
# Env overrides:
#   CLAUDE_BASE_DIR     defaults to $HOME/repo/claude-base
#   CLAUDE_BASE_REMOTE  defaults to git@github.com:jayman82/claude-base.git
#                       (or use https://github.com/... for HTTPS clone)
#
# Source of truth: claude-base/templates/standalone/bootstrap-claude-base.sh
# Vendored into each biz-* via setup.py. Do not hand-edit the vendored
# copy; update the template and re-run setup.py to refresh.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_NAME="$(basename "$REPO_DIR")"
CLAUDE_BASE_DIR="${CLAUDE_BASE_DIR:-$HOME/repo/claude-base}"
CLAUDE_BASE_REMOTE="${CLAUDE_BASE_REMOTE:-git@github.com:jayman82/claude-base.git}"

echo "Bootstrapping claude-base for $REPO_NAME"
echo "=========================================="
echo "  Repo:        $REPO_DIR"
echo "  claude-base: $CLAUDE_BASE_DIR"
echo

if [ ! -d "$CLAUDE_BASE_DIR" ]; then
    echo "claude-base not found — cloning from $CLAUDE_BASE_REMOTE ..."
    mkdir -p "$(dirname "$CLAUDE_BASE_DIR")"
    if ! git clone "$CLAUDE_BASE_REMOTE" "$CLAUDE_BASE_DIR"; then
        echo "[ERROR] git clone failed."
        echo "        If you need HTTPS, retry with:"
        echo "        CLAUDE_BASE_REMOTE=https://github.com/jayman82/claude-base.git $0"
        exit 1
    fi
    echo "  → cloned"
else
    echo "claude-base present — pulling latest ..."
    (cd "$CLAUDE_BASE_DIR" && git pull --ff-only) || {
        echo "[WARN] could not fast-forward claude-base; continuing with current state."
    }
fi
echo

echo "Linking shared skills into $REPO_DIR/.claude/skills/ ..."
(cd "$CLAUDE_BASE_DIR" && python3 setup.py)
echo

# Optional: Python deps used by tools/presentations and tools/claims-audit.
if command -v pip3 >/dev/null 2>&1; then
    echo "Checking Python deps (Pillow, PyYAML) ..."
    pip3 install --quiet --upgrade --user Pillow PyYAML 2>/dev/null || {
        echo "[WARN] could not install Pillow / PyYAML automatically."
        echo "       Run manually if needed: pip3 install Pillow PyYAML"
    }
fi
echo

echo "Done. Try one of these next:"
echo "  - python3 -m tools.presentations <deck.yaml>            # build a deck"
echo "  - python3 ~/repo/claude-base/tools/claims-audit/validate-claims.py --help"
echo "  - ls -la $REPO_DIR/.claude/skills/                      # confirm linked skills"

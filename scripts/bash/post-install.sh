#!/usr/bin/env bash
# post-install.sh — runs after `specify extension add worktrees`
# Ensures .worktrees/ is in .gitignore immediately so the directory
# is ignored before any worktree is ever created.

set -euo pipefail

to_wsl_path() {
  local p="$1"
  if [[ "$p" =~ ^([a-zA-Z]):[/\\](.*) ]]; then
    local drive="${BASH_REMATCH[1]}"
    local rest="${BASH_REMATCH[2]}"
    local drive_lower
    drive_lower=$(echo "$drive" | tr '[:upper:]' '[:lower:]')
    rest=$(echo "$rest" | tr '\\' '/')
    echo "/mnt/${drive_lower}/${rest}"
  elif [[ "$p" =~ ^([a-zA-Z]):$ ]]; then
    local drive="${BASH_REMATCH[1]}"
    local drive_lower
    drive_lower=$(echo "$drive" | tr '[:upper:]' '[:lower:]')
    echo "/mnt/${drive_lower}"
  else
    echo "$p"
  fi
}

REPO_ROOT=""
if [[ -f .git ]]; then
  raw_gitdir=$(grep '^gitdir:' .git 2>/dev/null | sed 's/^gitdir: *//; s/[[:space:]]*$//' || true)
  if [[ "$raw_gitdir" =~ ^[a-zA-Z]:[/\\] ]]; then
    wsl_gitdir="$(to_wsl_path "$raw_gitdir")"
    if [[ -f "$wsl_gitdir/commondir" ]]; then
      cd_rel=$(cat "$wsl_gitdir/commondir" 2>/dev/null || true)
      REPO_ROOT="$(cd "$wsl_gitdir/$cd_rel/.." 2>/dev/null && pwd)"
    fi
  fi
fi

if [[ -z "$REPO_ROOT" ]]; then
  if common_dir="$(git rev-parse --git-common-dir 2>/dev/null)"; then
    if [[ "$common_dir" != /* ]]; then
      common_dir="$(cd "$common_dir" 2>/dev/null && pwd)"
    fi
    REPO_ROOT="$(cd "$common_dir/.." 2>/dev/null && pwd)"
  else
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
  fi
fi

# Load dotworktrees_dir from config, fall back to .worktrees
CONFIG_FILE="$REPO_ROOT/.specify/extensions/worktrees/worktree-config.yml"
DOTWORKTREES_DIR=".worktrees"
if [[ -f "$CONFIG_FILE" ]]; then
  val=$(grep -E "^dotworktrees_dir:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*: *//; s/ *#.*//; s/^"//; s/"$//' || true)
  if [[ -n "$val" ]]; then DOTWORKTREES_DIR="$val"; fi
fi

GITIGNORE="$REPO_ROOT/.gitignore"

if ! grep -qxF "$DOTWORKTREES_DIR/" "$GITIGNORE" 2>/dev/null; then
  echo "$DOTWORKTREES_DIR/" >> "$GITIGNORE"
  echo "[worktrees] Added '$DOTWORKTREES_DIR/' to .gitignore" >&2
fi

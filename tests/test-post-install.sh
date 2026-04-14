#!/usr/bin/env bash
# Tests for post-install.sh
# Usage: bash tests/test-post-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POST_INSTALL="$SCRIPT_DIR/scripts/bash/post-install.sh"
PASS=0
FAIL=0
TOTAL=0

ORIG_DIR="$(pwd)"

setup_temp_repo() {
  TEMP_DIR=$(python3 -c "import os,tempfile; print(os.path.realpath(tempfile.mkdtemp()))")
  git -C "$TEMP_DIR" init -b main >/dev/null 2>&1
  echo "init" > "$TEMP_DIR/README.md"
  git -C "$TEMP_DIR" add . && git -C "$TEMP_DIR" commit -m "init" >/dev/null 2>&1
  mkdir -p "$TEMP_DIR/.specify/extensions/worktrees"
  cd "$TEMP_DIR"
  echo "$TEMP_DIR"
}

cleanup() {
  cd "$ORIG_DIR"
  if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
    TEMP_DIR=""
  fi
}

assert_file_contains() {
  local label="$1" file="$2" needle="$3"
  TOTAL=$((TOTAL + 1))
  if grep -qxF "$needle" "$file" 2>/dev/null; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label"
    echo "    expected '$needle' in $file"
  fi
}

assert_line_count() {
  local label="$1" file="$2" needle="$3" expected="$4"
  TOTAL=$((TOTAL + 1))
  local count
  count=$(grep -cxF "$needle" "$file" 2>/dev/null || echo "0")
  if [[ "$count" -eq "$expected" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label (expected $expected occurrences, got $count)"
  fi
}

echo "=== post-install.sh tests ==="
echo ""

# helper: run post-install inside temp repo so git rev-parse resolves correctly
run_post_install() {
  (cd "$TEMP_DIR" && bash "$POST_INSTALL" 2>/dev/null)
}

# Test 1: adds .worktrees/ to .gitignore when not present
echo "[1] adds .worktrees/ to .gitignore"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
run_post_install
assert_file_contains ".worktrees/ added" "$TEMP_DIR/.gitignore" ".worktrees/"
cleanup; trap - EXIT

# Test 2: does not duplicate if already present
echo "[2] idempotent — no duplicate entry"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
echo ".worktrees/" > "$TEMP_DIR/.gitignore"
run_post_install
assert_line_count "single entry" "$TEMP_DIR/.gitignore" ".worktrees/" 1
cleanup; trap - EXIT

# Test 3: reads custom dotworktrees_dir from config
echo "[3] respects custom dotworktrees_dir from config"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
echo 'dotworktrees_dir: ".wt"' > "$TEMP_DIR/.specify/extensions/worktrees/worktree-config.yml"
run_post_install
assert_file_contains "custom dir in .gitignore" "$TEMP_DIR/.gitignore" ".wt/"
cleanup; trap - EXIT

# Test 4: works when .gitignore doesn't exist yet
echo "[4] creates .gitignore if absent"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
rm -f "$TEMP_DIR/.gitignore"
run_post_install
assert_file_contains ".gitignore created with entry" "$TEMP_DIR/.gitignore" ".worktrees/"
cleanup; trap - EXIT

# Test 5: preserves existing .gitignore content
echo "[5] preserves existing .gitignore content"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
echo "node_modules/" > "$TEMP_DIR/.gitignore"
run_post_install
assert_file_contains "existing entry preserved" "$TEMP_DIR/.gitignore" "node_modules/"
assert_file_contains ".worktrees/ appended" "$TEMP_DIR/.gitignore" ".worktrees/"
cleanup; trap - EXIT

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

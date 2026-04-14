#!/usr/bin/env bash
# Tests for create-worktree.sh
# Usage: bash tests/test-create-worktree.sh
#
# Creates a temporary git repo, runs all tests, cleans up.
# Exit code 0 = all passed, 1 = failures.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CREATE_SCRIPT="$SCRIPT_DIR/scripts/bash/create-worktree.sh"
PASS=0
FAIL=0
TOTAL=0

# --- helpers ---

ORIG_DIR="$(pwd)"

setup_temp_repo() {
  TEMP_DIR=$(python3 -c "import os,tempfile; print(os.path.realpath(tempfile.mkdtemp()))")
  git -C "$TEMP_DIR" init -b main >/dev/null 2>&1
  echo "init" > "$TEMP_DIR/README.md"
  git -C "$TEMP_DIR" add . && git -C "$TEMP_DIR" commit -m "init" >/dev/null 2>&1
  mkdir -p "$TEMP_DIR/specs"
  cd "$TEMP_DIR"
  echo "$TEMP_DIR"
}

cleanup() {
  cd "$ORIG_DIR"
  if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
    git -C "$TEMP_DIR" worktree prune 2>/dev/null || true
    rm -rf "${TEMP_DIR}"--* 2>/dev/null || true
    rm -rf "$TEMP_DIR"
    TEMP_DIR=""
  fi
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$expected" == "$actual" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label"
    echo "    expected: $expected"
    echo "    actual:   $actual"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  TOTAL=$((TOTAL + 1))
  if echo "$haystack" | grep -qF "$needle"; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label"
    echo "    expected to contain: $needle"
    echo "    actual: $haystack"
  fi
}

assert_exit() {
  local label="$1" expected_code="$2"
  shift 2
  TOTAL=$((TOTAL + 1))
  set +e
  "$@" >/dev/null 2>&1
  local actual_code=$?
  set -e
  if [[ "$actual_code" -eq "$expected_code" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label (expected exit $expected_code, got $actual_code)"
  fi
}

# --- tests ---

echo "=== create-worktree.sh tests ==="
echo ""

# Test 1: --help exits 0
echo "[1] --help exits 0"
assert_exit "--help exits 0" 0 bash "$CREATE_SCRIPT" --help

# Test 2: missing branch name exits 1
echo "[2] missing branch name exits 1"
assert_exit "no branch exits 1" 1 bash "$CREATE_SCRIPT" --json

# Test 3: dry-run nested (default)
echo "[3] dry-run nested layout (default)"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --dry-run --repo-root "$TEMP_DIR" 005-test-feature)
assert_contains "output is JSON" '"branch":"005-test-feature"' "$output"
assert_contains "layout is nested" '"layout":"nested"' "$output"
assert_contains "path contains .worktrees" '.worktrees/005-test-feature' "$output"
assert_contains "dry_run is true" '"dry_run":true' "$output"
cleanup; trap - EXIT

# Test 4: dry-run sibling layout
echo "[4] dry-run sibling layout"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --dry-run --layout sibling --repo-root "$TEMP_DIR" 005-test-feature)
assert_contains "layout is sibling" '"layout":"sibling"' "$output"
base=$(basename "$TEMP_DIR")
assert_contains "sibling path pattern" "${base}--005-test-feature" "$output"
cleanup; trap - EXIT

# Test 5: dry-run with explicit --path
echo "[5] dry-run with explicit --path"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --dry-run --repo-root "$TEMP_DIR" --path /tmp/custom-wt 005-test-feature)
assert_contains "uses explicit path" '"/tmp/custom-wt"' "$output"
cleanup; trap - EXIT

# Test 6: --in-place skips worktree
echo "[6] --in-place skips worktree"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --in-place 005-test-feature)
assert_contains "worktree is false" '"worktree":false' "$output"
assert_contains "path is empty" '"path":""' "$output"
cleanup; trap - EXIT

# Test 7: SPECIFY_WORKTREE_PATH env override
echo "[7] SPECIFY_WORKTREE_PATH env override"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(SPECIFY_WORKTREE_PATH=/tmp/env-override bash "$CREATE_SCRIPT" --json --dry-run --repo-root "$TEMP_DIR" 005-test-feature)
assert_contains "uses env path" '"/tmp/env-override"' "$output"
cleanup; trap - EXIT

# Test 8: real worktree creation (nested)
echo "[8] real worktree creation (nested)"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --repo-root "$TEMP_DIR" 005-real-test 2>/dev/null)
assert_contains "worktree is true" '"worktree":true' "$output"
wt_path="$TEMP_DIR/.worktrees/005-real-test"
TOTAL=$((TOTAL + 1))
if [[ -d "$wt_path" ]]; then
  PASS=$((PASS + 1))
  echo "  PASS: worktree directory exists"
else
  FAIL=$((FAIL + 1))
  echo "  FAIL: worktree directory does not exist at $wt_path"
fi
# verify branch in worktree
branch=$(git -C "$wt_path" branch --show-current 2>/dev/null)
assert_eq "worktree is on correct branch" "005-real-test" "$branch"
# verify .gitignore was updated
TOTAL=$((TOTAL + 1))
if grep -qxF ".worktrees/" "$TEMP_DIR/.gitignore" 2>/dev/null; then
  PASS=$((PASS + 1))
  echo "  PASS: .worktrees/ in .gitignore"
else
  FAIL=$((FAIL + 1))
  echo "  FAIL: .worktrees/ not in .gitignore"
fi
# cleanup worktree
git -C "$TEMP_DIR" worktree remove "$wt_path" 2>/dev/null || true
cleanup; trap - EXIT

# Test 9: real worktree creation (sibling)
echo "[9] real worktree creation (sibling)"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --layout sibling --repo-root "$TEMP_DIR" 005-sibling-test 2>/dev/null)
assert_contains "worktree is true" '"worktree":true' "$output"
base=$(basename "$TEMP_DIR")
sibling_path="$(dirname "$TEMP_DIR")/${base}--005-sibling-test"
TOTAL=$((TOTAL + 1))
if [[ -d "$sibling_path" ]]; then
  PASS=$((PASS + 1))
  echo "  PASS: sibling worktree directory exists"
else
  FAIL=$((FAIL + 1))
  echo "  FAIL: sibling worktree directory does not exist at $sibling_path"
fi
branch=$(git -C "$sibling_path" branch --show-current 2>/dev/null)
assert_eq "sibling worktree on correct branch" "005-sibling-test" "$branch"
git -C "$TEMP_DIR" worktree remove "$sibling_path" 2>/dev/null || true
cleanup; trap - EXIT

# Test 10: duplicate worktree path blocked
echo "[10] duplicate worktree path blocked"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
bash "$CREATE_SCRIPT" --json --repo-root "$TEMP_DIR" 005-dup-test >/dev/null 2>&1
assert_exit "second create fails" 1 bash "$CREATE_SCRIPT" --json --repo-root "$TEMP_DIR" 005-dup-test
git -C "$TEMP_DIR" worktree remove "$TEMP_DIR/.worktrees/005-dup-test" 2>/dev/null || true
cleanup; trap - EXIT

# Test 11: config file overrides default layout
echo "[11] config file overrides default layout"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
mkdir -p "$TEMP_DIR/.specify/extensions/worktrees"
echo 'layout: "sibling"' > "$TEMP_DIR/.specify/extensions/worktrees/worktree-config.yml"
output=$(bash "$CREATE_SCRIPT" --json --dry-run --repo-root "$TEMP_DIR" 005-config-test)
assert_contains "config overrides to sibling" '"layout":"sibling"' "$output"
cleanup; trap - EXIT

# Test 12: branch with slashes handled
echo "[12] branch name with slashes sanitized"
TEMP_DIR=$(setup_temp_repo)
trap cleanup EXIT
output=$(bash "$CREATE_SCRIPT" --json --dry-run --repo-root "$TEMP_DIR" feature/user-auth)
assert_contains "slashes replaced" 'feature-user-auth' "$output"
cleanup; trap - EXIT

# --- summary ---
echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

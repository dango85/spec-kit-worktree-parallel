#!/usr/bin/env bash
# Compute next branch (dry-run), create a git worktree for it, emit merged JSON for /speckit.specify.
# Requires the Spec Kit Git extension (create-new-feature.sh). For worktree-first SDD, disable
# before_specify → speckit.git.feature so the primary checkout is not switched.
#
# Usage:
#   prepare-specify-worktree.sh [--json] <feature description — same text as /speckit.specify>
#
set -euo pipefail

JSON_MODE=false
if [[ "${1:-}" == "--json" ]]; then
  JSON_MODE=true
  shift
fi

FEATURE_DESC="$*"
if [[ -z "${FEATURE_DESC// }" ]]; then
  echo "Error: feature description required (same text the user passed to /speckit.specify)" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository" >&2
  exit 1
}

GIT_NEW_FEATURE="$REPO_ROOT/.specify/extensions/git/scripts/bash/create-new-feature.sh"
if [[ ! -f "$GIT_NEW_FEATURE" ]]; then
  echo "Error: Git extension not found at $GIT_NEW_FEATURE" >&2
  echo "Install: specify extension add git" >&2
  exit 1
fi

HERE="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_WT="$HERE/create-worktree.sh"

DRY_JSON="$("$GIT_NEW_FEATURE" --dry-run --json "$FEATURE_DESC")" || exit 1

BRANCH_NAME="$(printf '%s' "$DRY_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('BRANCH_NAME',''))")"
if [[ -z "$BRANCH_NAME" ]]; then
  echo "Error: create-new-feature --dry-run did not return BRANCH_NAME" >&2
  echo "$DRY_JSON" >&2
  exit 1
fi

WT_JSON="$("$CREATE_WT" --json "$BRANCH_NAME")" || exit 1

if $JSON_MODE; then
  _f1="$(mktemp)" _f2="$(mktemp)"
  trap 'rm -f "$_f1" "$_f2"' EXIT
  printf '%s' "$DRY_JSON" >"$_f1"
  printf '%s' "$WT_JSON" >"$_f2"
  python3 - "$_f1" "$_f2" <<'PY'
import json
import shutil
import shlex
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    dry = json.load(f)
with open(sys.argv[2], encoding="utf-8") as f:
    wt = json.load(f)

path = wt.get("path") or ""
out = {
    "branch": wt.get("branch") or dry.get("BRANCH_NAME"),
    "worktree": bool(wt.get("worktree")),
    "path": path,
    "layout": wt.get("layout", ""),
    "speckit_repo_root": path,
    "BRANCH_NAME": dry.get("BRANCH_NAME"),
    "FEATURE_NUM": dry.get("FEATURE_NUM"),
    "prepare_phase": "before_specify",
}
hints = []
if path:
    q = shlex.quote(path)
    if shutil.which("cursor"):
        hints.append(f"cursor {q}")
    if shutil.which("code"):
        hints.append(f"code {q}")
    if sys.platform == "darwin":
        hints.append(f"open -a Cursor {q}")
out["open_ide_hints"] = hints
out["open_ide_hint"] = hints[0] if hints else None
print(json.dumps(out, indent=2))
PY
else
  echo "$WT_JSON"
  echo "$DRY_JSON"
fi

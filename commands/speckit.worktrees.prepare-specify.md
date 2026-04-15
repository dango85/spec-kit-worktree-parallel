---
description: "Worktree-first SDD: reserve branch name, create git worktree, then /speckit.specify runs inside it (before_specify hook)"
---

# Prepare worktree for Specify (worktree-first)

Use this command when it is registered as a **`before_specify`** hook (recommended) or when the user wants **specs and SDD work to live inside a new git worktree** before writing `spec.md`.

## User input

```text
$ARGUMENTS
```

Pass the **same feature description** the user gave to **`/speckit.specify`** (verbatim). Do not invent a shorter description unless the user only gave a title and you must proceed.

## Prerequisites

1. **Git extension** must be installed (`specify extension add git`) so `create-new-feature.sh` exists under `.specify/extensions/git/scripts/bash/`.
2. **Disable** `before_specify → speckit.git.feature` in `.specify/extensions.yml` when using this flow, so the **primary** checkout is not switched to the feature branch (the worktree holds the branch instead). See the extension README *Parallel agents and the Git extension*.
3. `git worktree` available.

## What to run

From the **repository root** (primary clone is fine — this script does not switch its `HEAD`):

```bash
bash "$(git rev-parse --show-toplevel)/.specify/extensions/worktrees/scripts/bash/prepare-specify-worktree.sh" --json $ARGUMENTS
```

If `$ARGUMENTS` is empty, stop and ask the user for a feature description.

## After the script succeeds

1. Parse the JSON on stdout. Key fields:
   - **`speckit_repo_root`** / **`path`**: absolute path of the new worktree — **use this as the working directory** for every file operation in the rest of **`/speckit.specify`** (see core `specify.md` *Worktree root* section when using a fork that includes it).
   - **`BRANCH_NAME`**, **`FEATURE_NUM`**: from dry-run numbering (for reference).
   - **`open_ide_hint`** / **`open_ide_hints`**: paste the **first** hint to the user. Typical forms:
     - `cursor <path>` — [install `cursor` in PATH](https://github.com/link2004/git-worktree-cursor#-troubleshooting) (Cursor: Command Palette → “Shell Command: Install 'cursor' command in PATH”).
     - `code <path>` — VS Code.
     - `open -a Cursor <path>` — macOS fallback.

2. Tell the user clearly: **“Open this folder in Cursor (or run the hint above), then continue `/speckit.specify` in that window.”** If they stay in the primary workspace, spec files may still land on the primary tree.

3. If the user cannot switch windows, run remaining shell steps with explicit `cd` to **`speckit_repo_root`** before each `mkdir` / write.

## Rules

- Run **at most once** per feature (same as `create-new-feature.sh` dry-run semantics).
- Do not run `speckit.git.feature` in the same session for the same feature if this prepare step already created the branch in the worktree.

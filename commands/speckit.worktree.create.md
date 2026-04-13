---
description: "Spawn an isolated git worktree for a feature branch (default-on, configurable layout)"
---

# Create Worktree

Spawn an isolated git worktree for a feature branch so you can work on multiple features — or run multiple agents — in parallel without switching branches.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). The user may specify:
- A branch name (e.g., `005-user-auth`)
- `current` to create a worktree for the current branch
- `--in-place` or `--no-worktree` to skip worktree creation entirely

## Prerequisites

1. Verify the project is a git repository (`git rev-parse --show-toplevel`)
2. Verify `git worktree` is available (`git worktree list` succeeds)

## Configuration

Read configuration from `.specify/extensions/worktree-parallel/worktree-config.yml` if it exists. Defaults apply when the file is absent.

| Key | Default | Description |
|-----|---------|-------------|
| `layout` | `sibling` | `sibling` — worktree at `../<repo>--<branch>` (IDE-friendly); `nested` — at `.worktrees/<branch>/` inside repo |
| `auto_create` | `true` | When `true`, the `after_specify` hook creates a worktree without prompting |
| `sibling_pattern` | `{{repo}}--{{branch}}` | Name pattern for sibling directories |
| `dotworktrees_dir` | `.worktrees` | Subdirectory name for nested layout |

Environment variable `SPECIFY_WORKTREE_PATH` overrides the computed path entirely.

## Outline

1. **Determine target branch**:
   - If user specifies a branch name, use that
   - If user says `current`, use the output of `git branch --show-current`
   - If no input and this is an `after_specify` hook call, use the branch that `/speckit.specify` just created (read from `SPECIFY_FEATURE` env var or the most recent feature branch)
   - Validate the branch exists in git (local or remote)

2. **Invoke the script**:
   Run the deterministic bash script shipped with this extension:

   ```bash
   bash "$(dirname "$0")/../scripts/bash/create-worktree.sh" \
     --json \
     [--layout sibling|nested] \
     [--path <override>] \
     [--in-place] \
     [--dry-run] \
     "$BRANCH_NAME"
   ```

   The script reads `worktree-config.yml` automatically and outputs JSON:

   ```json
   {"branch":"005-user-auth","worktree":true,"path":"/Users/me/code/MyProject--005-user-auth","layout":"sibling"}
   ```

   If the script is unavailable (e.g., non-bash environment), perform the equivalent operations directly:
   - Resolve the worktree path based on layout config
   - Run `git worktree add -b <branch> <path> <base-ref>` (new branch) or `git worktree add <path> <branch>` (existing branch)
   - For nested layout, ensure `.worktrees/` is in `.gitignore`

3. **Verify spec artifacts**: Check that `specs/<branch>/` exists in the new worktree. List which artifacts are present (spec.md, plan.md, tasks.md).

4. **Report**: Output a summary:

   ```markdown
   ## Worktree Created

   | Field | Value |
   |-------|-------|
   | **Branch** | 005-user-auth |
   | **Layout** | sibling |
   | **Worktree path** | /Users/me/code/MyProject--005-user-auth |
   | **Spec artifacts** | spec.md, plan.md |

   **Next steps:**
   - Open the worktree directory in your IDE or a new terminal
   - Run `/speckit.implement` from the worktree root
   - Run `/speckit.worktree.list` to see all active worktrees
   ```

## Rules

- **Default behavior is to create a worktree** — only skip if the user explicitly passes `--in-place` or `--no-worktree`, or `auto_create` is `false` in config and this is a hook call
- **One worktree per branch** — refuse to create a duplicate; report the existing path instead
- **Never modify the primary checkout** — worktree operations happen in the new directory only
- **Always update .gitignore for nested layout** — add the `dotworktrees_dir` value if not present
- **Validate branch exists** — for existing branches; for new branches the `after_specify` hook should have already created the branch via the git extension

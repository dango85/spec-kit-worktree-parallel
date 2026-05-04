---
description: "Create a git worktree first, then write the feature spec inside that isolated checkout"
---

# Worktree-First Specify

Create an isolated git worktree before writing the feature specification. Use this command when several features or agents may run in parallel and you want the spec files, plan, tasks, commits, and terminal cwd to all belong to the same worktree from the start.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding. The user input should include:
- A feature branch name or slug (for example `005-user-auth`)
- The feature description to specify
- Optional worktree flags accepted by `/speckit.worktrees.create`, such as `--layout sibling`, `--path <dir>`, or `--base-ref HEAD`

If the branch name is missing, ask for it before creating anything. If the feature description is missing, create the worktree only after the user confirms they want to continue specifying in that worktree.

## Prerequisites

1. Verify the current directory is the primary git repository (`git rev-parse --show-toplevel`)
2. Verify the working tree has the intended base state for the new feature
3. Verify `git worktree` is available (`git worktree list` succeeds)

## Outline

1. **Parse the request**:
   - Extract the target branch name
   - Extract any worktree flags
   - Preserve the remaining text as the feature description

2. **Create the worktree first**:
   Run the deterministic worktree script:

   ```bash
   bash "$(dirname "$0")/../scripts/bash/create-worktree.sh" \
     --json \
     [--layout sibling|nested] \
     [--base-ref HEAD|main|origin/main|...] \
     [--path <override>] \
     "$BRANCH_NAME"
   ```

   If the worktree already exists for that branch, use the existing path and continue there.

3. **Switch all follow-up work to the worktree**:
   - Treat the returned worktree path as the project root for this feature
   - Run all file reads, writes, scripts, git commands, and follow-up Spec Kit steps from that path
   - If using an IDE, open the returned path as its own window before continuing

4. **Write the spec inside the worktree**:
   Continue the normal `/speckit.specify` workflow from the worktree root using the feature description. Spec artifacts should be created under:

   ```text
   <worktree>/specs/<branch>/
   ```

   Do not write spec artifacts to the primary checkout.

5. **Report**:
   Output a concise summary:

   ```markdown
   ## Worktree-First Spec Ready

   | Field | Value |
   |-------|-------|
   | **Branch** | 005-user-auth |
   | **Worktree path** | /Users/me/code/my-project/.worktrees/005-user-auth |
   | **Spec root** | /Users/me/code/my-project/.worktrees/005-user-auth/specs/005-user-auth |

   **Next steps:**
   - Continue `/speckit.plan` from the worktree root
   - Keep commits and PR work inside that worktree
   - Return to the primary checkout only for `/speckit.worktrees.clean`
   ```

## Rules

- Create or reuse the worktree before writing any spec files
- Never run `git checkout` in the primary checkout as part of this workflow
- Prefer `--base-ref HEAD` when the primary checkout has committed spec seed work that the new worktree must include
- Keep all generated artifacts, plans, tasks, implementation changes, commits, and PR operations in the worktree
- Use `/speckit.worktrees.clean` from the primary checkout after the PR is merged or the worktree is no longer needed

# Spec Kit Worktree Parallel: Lessons Learned

## WSL & Windows IDE Worktree Interoperability

1. **Worktree Pointers in Mixed Windows / WSL Environments**:
   - Windows IDEs (such as Antigravity) expect absolute Windows paths (`C:/...`) in the worktree's `.git` file (`gitdir: C:/...`).
   - When Windows IDE invokes bash, commands execute inside the WSL environment where Linux `git` runs.
   - WSL `git` fails on `C:/...` paths unless bridged because Linux has no `C:` drive concept.
   - `scripts/bash/create-worktree.sh` bridges this in-memory by translating `gitdir: C:/...` to `/mnt/c/...` when resolving `REPO_ROOT` and running `git` commands, while preserving `C:/...` on disk for the Windows IDE.

2. **Worktree Creation from Inside a Worktree**:
   - When a user or IDE is already inside a worktree (`.worktrees/<branch-1>`), `git rev-parse --git-common-dir` resolves to the primary repository's `.git` directory (`<repo>/.git`), allowing new worktrees (`.worktrees/<branch-2>`) to be created at the repo root level rather than nested inside `<branch-1>`.

3. **Line Endings for Shell Scripts**:
   - Shell scripts (`*.sh`) executed in WSL from Windows checkouts must preserve `LF` line endings (`.gitattributes: *.sh text eol=lf`) to avoid syntax errors with carriage returns (`\r`).

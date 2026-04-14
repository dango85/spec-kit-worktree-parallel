# Changelog

## 1.2.1 (2026-04-14)

### Removed
- `modifies_hooks` integration (revert of PR #1). The extension no longer disables the git extension’s `before_specify → speckit.git.feature` hook on install. If you rely on a stable primary branch with parallel worktrees, disable or adjust that hook manually in your Spec Kit config.

## 1.2.0 (2026-04-14)

### Changed
- Default layout switched from `sibling` to `nested` — worktrees now created at `.worktrees/<branch>/` inside the repo by default
- Sibling layout (`../<repo>--<branch>`) remains available via `layout: "sibling"` in config

### Added
- `post_install` lifecycle script — adds `.worktrees/` to `.gitignore` at install time (not just at first worktree creation)
- README section "How worktrees stay isolated" documenting gitignore + commit isolation model

## 1.0.0 (2026-04-13)

### Added
- `speckit.worktrees.create` command — spawn isolated worktrees with configurable layout
- `speckit.worktrees.list` command — dashboard of all active worktrees with spec-artifact and task progress
- `speckit.worktrees.clean` command — safe cleanup of merged, orphaned, or stale worktrees
- `after_specify` hook — auto-creates worktree after feature specification (configurable)
- Two layout modes: **sibling** (`../<repo>--<branch>`) and **nested** (`.worktrees/<branch>/`)
- Bash script `create-worktree.sh` for deterministic worktree creation with JSON output
- Per-repo configuration via `worktree-config.yml`
- `SPECIFY_WORKTREE_PATH` environment variable for path overrides
- `--in-place` / `--no-worktree` opt-out for single-agent flows

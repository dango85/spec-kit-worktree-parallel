# Changelog

## 1.2.0 (2026-04-14)

### Changed
- Default layout switched from `sibling` to `nested` — worktrees now created at `.worktrees/<branch>/` inside the repo by default
- Sibling layout (`../<repo>--<branch>`) remains available via `layout: "sibling"` in config

### Added
- `post_install` lifecycle script — adds `.worktrees/` to `.gitignore` at install time (not just at first worktree creation)
- README section "How worktrees stay isolated" documenting gitignore + commit isolation model

## 1.1.0 (2026-04-13)

### Added
- `modifies_hooks` declaration: automatically disables `before_specify -> speckit.git.feature` on install (with user consent) so the primary checkout stays on a stable branch
- Requires Spec Kit with `modifies_hooks` support ([github/spec-kit#2209](https://github.com/github/spec-kit/pull/2209))

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

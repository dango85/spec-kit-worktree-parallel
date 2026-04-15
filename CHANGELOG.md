# Changelog

## 1.4.0 (2026-04-16)

### Changed (**breaking**)
- **Hooks:** `after_specify → speckit.worktrees.create` replaced by **`before_specify → speckit.worktrees.prepare-specify`** so a **git worktree + branch** exist **before** `/speckit.specify` writes files.
- **New script** `scripts/bash/prepare-specify-worktree.sh` — calls Git extension `create-new-feature.sh --dry-run --json`, then `create-worktree.sh`; merged JSON includes **`speckit_repo_root`**, **`open_ide_hint`**, **`open_ide_hints`** (`cursor`, `code`, macOS `open -a Cursor`).
- **New command** `speckit.worktrees.prepare-specify.md` for the hook.

### Documentation
- README: Cursor open shortcuts, upgrade notes (remove stale `after_specify`), v1.4 ordering.

### Integration
- Use a **spec-kit fork** whose `templates/commands/specify.md` includes the **Worktree root (`speckit_repo_root`)** section (see companion changes in `github/spec-kit` / your fork).

## 1.3.2 (2026-04-15)

### Added
- README section **Cursor IDE: best results with Spec Kit** — `/worktree`, `.cursor/worktrees.json`, avoiding double isolation with this extension’s `after_specify` hook; links to [Cursor worktrees](https://cursor.com/docs/configuration/worktrees) and Cursor CLI
- **`examples/cursor-worktrees.spec-kit.example.json`** and **`examples/README.md`** — starter `worktrees.json` for copying `.env` / optional `.specify` into Cursor-managed checkouts

### Changed
- **`install_notes`**: points Cursor users at official worktrees docs and the new README section

## 1.3.1 (2026-04-14)

### Added
- `extension.install_notes` in `extension.yml` — after `specify extension add`, Specify prints this note when using a `specify-cli` build that supports `install_notes` (see upstream spec-kit). Reminds you to optionally disable the Git extension’s `before_specify` hook for parallel worktrees; full `.specify/extensions.yml` snippet remains in the README

## 1.3.0 (2026-04-14)

### Added
- README section **Parallel agents and the Git extension**: manual `.specify/extensions.yml` change to disable Git’s `before_specify` hook when you need a stable primary checkout; branch base `--base-ref HEAD`; honest note on `after_specify` ordering vs running specify from the worktree root
- Command doc prerequisites: Git extension vs `git` CLI, and corrected branch-creation rule (worktree can create the branch with `git worktree add -b`)

### Changed
- Documentation-only release aligned with Spec Kit maintainer guidance: no cross-extension hook mutation on install; optional future **preset** for worktree-first command overrides called out in README

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

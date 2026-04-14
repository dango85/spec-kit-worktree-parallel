# spec-kit-worktree-parallel

[![Tests](https://github.com/dango85/spec-kit-worktree-parallel/actions/workflows/test.yml/badge.svg)](https://github.com/dango85/spec-kit-worktree-parallel/actions/workflows/test.yml)

A [Spec Kit](https://github.com/github/spec-kit) extension for **default-on** git worktree isolation — work on multiple features (or run parallel agents) without checkout switching.

## Why another worktree extension?

The community [spec-kit-worktree](https://github.com/Quratulain-bilal/spec-kit-worktree) extension is a good starting point. This extension differs in three ways:

1. **Default-on** — worktrees are created automatically after `/speckit.specify`. Opt *out* with `--in-place`, rather than opting in.
2. **Nested layout by default** — worktrees live at `.worktrees/<branch>/` inside the repo (gitignored, self-contained). Sibling-dir layout (`../<repo>--<branch>`) is available as an option for IDE-per-feature workflows.
3. **Deterministic bash script** — a real script (`create-worktree.sh`) with `--json` output, `--dry-run`, and `SPECIFY_WORKTREE_PATH` override, suitable for CI and scripted workflows.

## Installation

```bash
specify extension add --from https://github.com/dango85/spec-kit-worktree-parallel/archive/refs/tags/v1.0.0.zip
```

## Layout modes

### Nested (default)

Worktrees live inside the repo under `.worktrees/` (auto-gitignored):

```
my-project/
├── .worktrees/
│   ├── 005-user-auth/           ← worktree
│   ├── 006-chat/                ← worktree
├── specs/
├── src/
```

Self-contained — everything stays in one directory. `.worktrees/` is added to `.gitignore` at install time so worktree directories are never accidentally committed to the main repo. Work inside each worktree is committed on its own feature branch.

### Sibling

Each worktree is a sibling directory of the primary clone:

```
parent/
├── my-project/                  ← primary checkout (main)
├── my-project--005-user-auth/   ← worktree (005-user-auth branch)
├── my-project--006-chat/        ← worktree (006-chat branch)
```

Open each directory in its own IDE window. Switch with `layout: "sibling"` in `worktree-config.yml`.

## Configuration

Create `.specify/extensions/worktrees/worktree-config.yml` to override defaults:

```yaml
layout: "nested"            # nested | sibling
auto_create: true            # false to prompt instead of auto-creating
sibling_pattern: "{{repo}}--{{branch}}"
dotworktrees_dir: ".worktrees"
```

## How worktrees stay isolated

- **On install** (`specify extension add`): `.worktrees/` is added to `.gitignore` so the directory is ignored before any worktree exists
- **On create** (`/speckit.worktrees.create`): the script double-checks `.gitignore` as a safety net
- **Commits stay on the right branch**: each worktree has its own working tree and index — `git add` and `git commit` inside a worktree only affect that worktree's branch, not the main repo
- **Cleanup**: `/speckit.worktrees.clean` removes worktree directories; it never deletes the git branch itself

## Commands

| Command | Description | Modifies files? |
|---------|-------------|-----------------|
| `/speckit.worktrees.create` | Spawn a worktree for a feature branch | Yes |
| `/speckit.worktrees.list` | Dashboard: status, artifacts, tasks | No |
| `/speckit.worktrees.clean` | Remove merged/stale worktrees | Yes |

## Hook

**`after_specify`** — automatically creates a worktree after a new feature is specified. Controlled by the `auto_create` config value.

## Script usage

The bash script can be called directly for automation:

```bash
# Create a nested worktree for branch 005-user-auth (default)
bash scripts/bash/create-worktree.sh --json 005-user-auth

# Sibling layout instead
bash scripts/bash/create-worktree.sh --json --layout sibling 005-user-auth

# Explicit path
bash scripts/bash/create-worktree.sh --json --path /tmp/my-worktree 005-user-auth

# Dry run (compute path without creating)
bash scripts/bash/create-worktree.sh --json --dry-run 005-user-auth

# Skip worktree (single-agent mode)
bash scripts/bash/create-worktree.sh --in-place 005-user-auth
```

## Environment variables

| Variable | Description |
|----------|-------------|
| `SPECIFY_WORKTREE_PATH` | Override computed worktree path entirely |
| `SPECIFY_FEATURE` | Current feature name (set by spec-kit) |

## Related

- [#61](https://github.com/github/spec-kit/issues/61) — Spawn worktree when creating new branch (36+ upvotes)
- [#1476](https://github.com/github/spec-kit/issues/1476) — Native worktree support for parallel agents
- [#1940](https://github.com/github/spec-kit/issues/1940) — Git operations extracted to extension (closed)

## Requirements

- Spec Kit >= 0.4.0
- Git >= 2.15.0 (worktree support)

## License

MIT

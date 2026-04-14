# spec-kit-worktree-parallel

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

Self-contained — everything stays in one directory. `.worktrees/` is auto-added to `.gitignore`.

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

## Commands

| Command | Description | Modifies files? |
|---------|-------------|-----------------|
| `/speckit.worktrees.create` | Spawn a worktree for a feature branch | Yes |
| `/speckit.worktrees.list` | Dashboard: status, artifacts, tasks | No |
| `/speckit.worktrees.clean` | Remove merged/stale worktrees | Yes |

## Hooks

**`after_specify`** — automatically creates a worktree after a new feature is specified. Controlled by the `auto_create` config value.

## Hook overrides

This extension declares `modifies_hooks` in `extension.yml` to **disable** the git extension's `before_specify -> speckit.git.feature` hook on install. This keeps the primary checkout on a stable branch (e.g. `main`) while worktrees handle feature branch isolation.

During `specify extension add`, you will see a consent prompt:

```
Extension 'worktrees' requests the following hook modifications:

  Hook                Target Extension  Command               Action   Reason
  before_specify      git               speckit.git.feature   disable  Worktree-parallel keeps primary checkout...

Apply these modifications? [Y/n]:
```

Answering **Y** disables the hook. Answering **N** installs the extension without modifying hooks (you can disable it manually in `.specify/extensions.yml`). Removing the extension via `specify extension remove worktrees` restores the original hook state.

**Requires**: Spec Kit with `modifies_hooks` support (see [github/spec-kit#2209](https://github.com/github/spec-kit/pull/2209)).

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

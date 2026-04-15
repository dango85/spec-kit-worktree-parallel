# spec-kit-worktree-parallel

[![Tests](https://github.com/dango85/spec-kit-worktree-parallel/actions/workflows/test.yml/badge.svg)](https://github.com/dango85/spec-kit-worktree-parallel/actions/workflows/test.yml)

**Contributing:** use a **branch + pull request** into `main` — see [CONTRIBUTING.md](CONTRIBUTING.md).

A [Spec Kit](https://github.com/github/spec-kit) extension for **default-on** git worktree isolation — work on multiple features (or run parallel agents) without checkout switching.

## Why another worktree extension?

The community [spec-kit-worktree](https://github.com/Quratulain-bilal/spec-kit-worktree) extension is a good starting point. This extension differs in these ways:

1. **Worktree-first SDD (v1.4+)** — **`before_specify → speckit.worktrees.prepare-specify`** runs `prepare-specify-worktree.sh`: dry-run branch numbering (`create-new-feature.sh --dry-run`), then **`git worktree add -b`** so the feature branch exists **only** in the new worktree. Pair with a **Spec Kit fork** that includes the `specify.md` *Worktree root (`speckit_repo_root`)* section so `/speckit.specify` writes **`specs/`** under that path. **Disable** Git’s `speckit.git.feature` `before_specify` hook when using prepare (see below).
2. **Nested layout by default** — worktrees live at `.worktrees/<branch>/` inside the repo (gitignored). Sibling layout (`../<repo>--<branch>`) is optional in `worktree-config.yml`.
3. **Deterministic bash** — `create-worktree.sh` and `prepare-specify-worktree.sh` with `--json`, `--dry-run`, `--base-ref`, and `SPECIFY_WORKTREE_PATH` override.

This extension **does not** change another extension’s configuration on install (for example it does not disable the Git extension’s hooks). You opt into hook changes explicitly in `.specify/extensions.yml` when you need them (see below).

## Installation

```bash
specify extension add worktrees --from https://github.com/dango85/spec-kit-worktree-parallel/archive/refs/tags/v1.4.0.zip
```

## Easiest ways to open Cursor on the new worktree

After **`speckit.worktrees.prepare-specify`** (or `prepare-specify-worktree.sh --json`), the JSON includes **`open_ide_hint`** and **`open_ide_hints`**:

1. **`cursor <path>`** — Install the CLI once: Cursor → Command Palette → **“Shell Command: Install 'cursor' command in PATH”**, then run the printed command in any terminal (same pattern as [git-worktree-cursor](https://github.com/link2004/git-worktree-cursor)).
2. **`code <path>`** — If you use VS Code instead.
3. **macOS:** `open -a Cursor <path>` — when the app bundle is named **Cursor**.

Then **continue `/speckit.specify` in that window** so the agent’s cwd matches the worktree.

## Upgrading from v1.3.x

- Hooks moved from **`after_specify`** to **`before_specify`**. After `specify extension update worktrees` (or reinstall), open **`.specify/extensions.yml`** and **remove any stale `hooks.after_specify` entry** for extension **`worktrees`** if the updater left it behind.
- Use a **spec-kit fork** that ships the **`speckit_repo_root`** paragraph in `templates/commands/specify.md` (see [dango85/spec-kit](https://github.com/dango85/spec-kit) if you track that fork).

## Cursor IDE: best results with Spec Kit

Cursor implements **editor-native** isolation: **`/worktree`** keeps the **rest of that chat** in a **separate checkout**, with optional **`.cursor/worktrees.json`** to run setup (deps, env files) using **`$ROOT_WORKTREE_PATH`**. See the official **[Cursor worktrees](https://cursor.com/docs/configuration/worktrees)** documentation and the **[Cursor CLI `--worktree` flag](https://cursor.com/docs/cli/using.md#cli-worktrees)** for the same behavior outside the UI.

### Recommended pattern (agent focus = one tree)

1. **Start the feature** with **`/worktree …`** (or **`/best-of-n`** when comparing models). That aligns **agent tools and cwd** with Cursor’s isolated checkout.
2. Add **`.cursor/worktrees.json`** at your **main project root** so each new checkout gets a working dev environment (copy `.env`, install packages, migrations, etc.). Copy and edit **`examples/cursor-worktrees.spec-kit.example.json`** from this repo as a starting point for Spec Kit repos.
3. Run **`/speckit.specify`**, then plan / tasks / implement **in the same chat** so spec artifacts and edits stay in that checkout.

### How this extension fits (do not double-isolate by accident)

| Mechanism | Who creates it | Typical use |
|-----------|----------------|-------------|
| **Cursor `/worktree`** | Cursor (`~/.cursor/worktrees`, cleanup, setup hooks) | **Best default for Cursor users** — session root matches isolation. |
| **This extension (`before_specify` prepare)** | `git worktree add` under **`.worktrees/`** or sibling dirs **before** specify | **In-repo** SDD + **list/clean**; combine with **fork `specify.md`** for specs inside the worktree. |

Using **both** at once for the same feature usually adds **confusion** (two different worktree locations and mental models). For **Cursor-heavy** teams:

- Prefer **`/worktree` + `.cursor/worktrees.json`** when you want **Cursor-managed** checkouts only; then **disable** this extension’s **`before_specify`** hook in `.specify/extensions.yml` (or do not install worktrees) so you do not stack two systems.

If you use **this extension’s prepare hook**, you already get an in-repo git worktree **before** specify — use **`open_ide_hint`** instead of `/worktree` for that feature unless you know why you need both.

### Summary

- **Cursor:** isolation + agent focus → **`/worktree`** + **`worktrees.json`**.  
- **This extension:** **`git worktree`** automation, dashboards, cleanup — complements Cursor; it does **not** replace Cursor’s chat root behavior.

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

## Parallel agents and the Git extension

**Git extension vs `git` on your PATH:** This extension requires the **`git` CLI** only. It does not require the Spec Kit **Git extension** (`speckit.git.*`). That distinction matters because the Git extension registers **`before_specify → speckit.git.feature`**, which runs `git checkout` / `git checkout -b` on **whatever directory the agent is using as the repo root**. On a **shared** primary clone, that moves `HEAD` for everyone and fights parallel worktrees.

**What this extension does instead:** `create-worktree.sh` uses **`git worktree add`** (and **`git worktree add -b`** for a new branch). That creates the feature branch **inside the new worktree** and leaves the primary checkout’s `HEAD` alone.

**If the Git extension is installed and you want a stable primary checkout:** edit **`.specify/extensions.yml`** and set **`enabled: false`** on the `before_specify` entry whose **`extension`** is **`git`** and **`command`** is **`speckit.git.feature`**. Your file may include extra keys (`optional`, `prompt`, …); only `enabled` needs to change.

```yaml
hooks:
  before_specify:
    - extension: git
      command: speckit.git.feature
      enabled: false
      optional: false
      # …other keys from your install stay as-is…
```

After disabling that hook, **feature branch naming** is no longer applied by `speckit.git.feature` before specify. Use **`create-new-feature.sh --dry-run --json`** from the Git extension if you still want the same numbering **without** a checkout, or agree on branch names in the specify step. **Branch from current `HEAD`** when creating a worktree: pass **`--base-ref HEAD`** to `create-worktree.sh` (default base is `main` / `origin/main` when present).

**v1.4 `before_specify` ordering:** The prepare hook runs **before** the `/speckit.specify` outline. The worktree and branch exist first; with a **patched `specify.md`** (fork) that honors **`speckit_repo_root`**, new **`specs/`** directories are created **inside** that worktree. Without the fork patch, the agent must still **`cd`** into the path from the hook JSON before writing files.

**Spec Kit 1.0.0:** The Git extension is expected to become **opt-in**. Do not assume `before_specify` / `speckit.git.feature` is always present; keep the worktree flow valid with Git extension off.

## Configuration

Create `.specify/extensions/worktrees/worktree-config.yml` to override defaults:

```yaml
layout: "nested"            # nested | sibling
auto_create: true           # legacy: only affects /speckit.worktrees.create when invoked manually (v1.4 uses before_specify prepare, not after_specify)
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
| `/speckit.worktrees.prepare-specify` | **Before specify:** branch dry-run + `git worktree add` + `open_ide_hint` JSON | Yes |
| `/speckit.worktrees.create` | Spawn a worktree for an existing branch (manual / CI) | Yes |
| `/speckit.worktrees.list` | Dashboard: status, artifacts, tasks | No |
| `/speckit.worktrees.clean` | Remove merged/stale worktrees | Yes |

## Hook

**`before_specify` → `speckit.worktrees.prepare-specify`** (mandatory by default) — runs **`prepare-specify-worktree.sh`** so worktree + branch exist **before** `/speckit.specify` writes specs. **Disable Git `speckit.git.feature` for the same event** when using this hook (see above).

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

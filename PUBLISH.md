# Publishing steps

## 1. Push to GitHub

```bash
cd /Users/abiyadav/SourceCode/spec-kit-worktree-parallel
gh repo create dango85/spec-kit-worktree-parallel --public --source . --push
# or manually:
git remote add origin https://github.com/dango85/spec-kit-worktree-parallel.git
git push -u origin main --tags
```

## 2. Submit catalog PR to github/spec-kit

Fork `github/spec-kit`, add the entry from `catalog-entry.json` to
`extensions/catalog.community.json` (alphabetical order, after `worktree`),
and add a row to the Community Extensions table in `README.md`:

```markdown
| [Worktree Parallel](https://github.com/dango85/spec-kit-worktree-parallel) | Default-on worktree isolation for parallel agents — sibling or nested layout | dango85 |
```

PR title: `Add Worktree Parallel extension to community catalog`

Reference issues: #61, #1476

## 3. Install in any repo

```bash
specify extension add --from https://github.com/dango85/spec-kit-worktree-parallel/archive/refs/tags/v1.0.0.zip
```

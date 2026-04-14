# Publishing steps

## 1. Land changes on `main` via pull request

Do **not** push routine commits directly to `main`. See [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
cd /Users/abiyadav/SourceCode/spec-kit-worktree-parallel
git fetch origin && git checkout -b your-branch origin/main
# … commit …
git push -u origin your-branch
gh pr create --base main --head your-branch
# After review, merge the PR on GitHub
```

Initial repo setup (one-time):

```bash
gh repo create dango85/spec-kit-worktree-parallel --public --source . --push
# or: git remote add origin https://github.com/dango85/spec-kit-worktree-parallel.git
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
specify extension add worktrees --from https://github.com/dango85/spec-kit-worktree-parallel/archive/refs/tags/v1.3.1.zip
```

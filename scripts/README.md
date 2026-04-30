# Documentation Rebuild Scripts

Scripts to rebuild and deploy documentation for all portfolio projects.

## Usage

### Rebuild all docs (stage changes locally)
```bash
./rebuild-all-docs.sh
```

This will:
1. Clone/pull all portfolio repos
2. Build mkdocs for each repo
3. Update local docs in the pages repo
4. Show what changed with `git status`

### Rebuild and auto-push
```bash
./rebuild-all-docs.sh --push
```

This will:
1. Do everything above
2. Auto-commit with timestamp: `docs: rebuild all portfolio documentation YYYY-MM-DD HH:MM:SS`
3. Push changes to GitHub

## What Gets Rebuilt

The script handles these repos:
- `chakraview-zero-trust-blueprint` → `zero-trust-blueprint/`
- `chakraview-enterprise-modernization` → `enterprise-modernization/`
- `chakraview-realtime-data-platform` → `realtime-data-platform/`
- `chakraview-data-engineering-patterns` → `data-engineering-patterns/`
- `chakraview-networking-sdn` → `networking-sdn/`

## Requirements

```bash
pip install mkdocs mkdocs-material pymdown-extensions
```

The script will auto-install if missing.

## Notes

- Script clones into `.build-tmp/` and cleans up after
- Only rebuilds repos that have `mkdocs.yml` and `docs/` directory
- Requires git and Python with pip
- Must be run from the GitHub Pages repo root or via full path

## Example Workflow

```bash
# Review what will change
./scripts/rebuild-all-docs.sh

# See the staged changes
git status
git diff --cached | less

# If satisfied, push
./scripts/rebuild-all-docs.sh --push

# Or commit manually for more control
git commit -m "docs: rebuild all portfolio documentation"
git push origin main
```

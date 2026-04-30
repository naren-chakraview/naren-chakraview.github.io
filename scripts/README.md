# Documentation Rebuild Scripts

Scripts to rebuild and deploy documentation for all portfolio projects from local clones.

## Requirements

The script assumes all portfolio repos are cloned in the parent directory:

```
~/portfolio/
├── naren-chakraview.github.io/          # GitHub Pages repo (you are here)
│   └── scripts/
│       └── rebuild-all-docs.sh
├── chakraview-zero-trust-blueprint/
├── chakraview-enterprise-modernization/
├── chakraview-realtime-data-platform/
├── chakraview-data-engineering-patterns/
└── chakraview-networking-sdn/
```

Install dependencies:
```bash
pip install mkdocs mkdocs-material pymdown-extensions
```

## Usage

### Rebuild all repos (stage changes locally)
```bash
./scripts/rebuild-all-docs.sh
```

This will:
1. Build mkdocs for all repos with docs (Material theme + Mermaid support)
2. Update docs in the GitHub Pages repo
3. Stage all changes in git (no push)

### Rebuild all repos and auto-push
```bash
./scripts/rebuild-all-docs.sh --push
```

This will:
1. Do everything above
2. Auto-commit with timestamp: `docs: rebuild all portfolio documentation YYYY-MM-DD HH:MM:SS`
3. Push to GitHub

### Rebuild single repo (stage locally)
```bash
./scripts/rebuild-all-docs.sh networking-sdn
```

Accepts either the repo name or output directory:
- `./scripts/rebuild-all-docs.sh chakraview-networking-sdn`
- `./scripts/rebuild-all-docs.sh networking-sdn`

### Rebuild single repo and auto-push
```bash
./scripts/rebuild-all-docs.sh networking-sdn --push
```

## Supported Repos

| Repo Name | Output Directory |
|-----------|---|
| `chakraview-zero-trust-blueprint` | `zero-trust-blueprint/` |
| `chakraview-enterprise-modernization` | `enterprise-modernization/` |
| `chakraview-realtime-data-platform` | `realtime-data-platform/` |
| `chakraview-data-engineering-patterns` | `data-engineering-patterns/` |
| `chakraview-networking-sdn` | `networking-sdn/` |

## Examples

### Quick fix: Rebuild just one repo
```bash
./scripts/rebuild-all-docs.sh networking-sdn
```

### Fix and deploy: Rebuild networking-sdn and push
```bash
./scripts/rebuild-all-docs.sh networking-sdn --push
```

### Review before pushing: Rebuild all, review, then push
```bash
./scripts/rebuild-all-docs.sh
git status
git diff --cached | less
git push origin main  # if satisfied
```

### Batch rebuild and deploy
```bash
./scripts/rebuild-all-docs.sh --push
```

## How It Works

1. Script reads each repo from local `~/portfolio/<repo-name>/`
2. Checks for `mkdocs.yml` and `docs/` directory
3. Builds mkdocs for that repo (installs deps if needed)
4. Copies built `site/` output to GitHub Pages repo
5. Stages all changes in git
6. Optionally commits and pushes (with `--push` flag)

## Key Advantages

✅ **No cloning** — Uses existing local repos (fast!)  
✅ **Single repo rebuilds** — Test Mermaid fixes without rebuilding everything  
✅ **Safe by default** — Stages changes locally before pushing  
✅ **Batch mode** — Rebuild all repos with one command  
✅ **Smart filtering** — Only rebuilds repos with mkdocs.yml  

## Troubleshooting

**"Repository not found"**
- Verify the repo is cloned in `~/portfolio/`
- Check directory name matches exactly

**"No mkdocs.yml found"**
- That repo doesn't have documentation yet
- Only repos with `mkdocs.yml` will rebuild

**Build failures**
- Run mkdocs manually to see detailed error:
  ```bash
  cd ~/portfolio/chakraview-networking-sdn
  mkdocs build
  ```

**Mermaid diagrams not rendering after rebuild**
- Check Material theme is being used
- Verify `pymdown-extensions` is installed
- Try rebuilding that repo: `./scripts/rebuild-all-docs.sh networking-sdn --push`

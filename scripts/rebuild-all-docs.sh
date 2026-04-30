#!/bin/bash

# Rebuild portfolio project documentation from local clones
# Usage:
#   ./rebuild-all-docs.sh [--push]              # Rebuild all repos
#   ./rebuild-all-docs.sh <repo-name> [--push]  # Rebuild single repo
#
# Examples:
#   ./rebuild-all-docs.sh                                  # All repos, stage changes
#   ./rebuild-all-docs.sh --push                          # All repos, push to GitHub
#   ./rebuild-all-docs.sh networking-sdn                  # Just networking-sdn
#   ./rebuild-all-docs.sh networking-sdn --push           # Just networking-sdn, push

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAGES_ROOT="$(dirname "$SCRIPT_DIR")"
PORTFOLIO_ROOT="$(dirname "$PAGES_ROOT")"
PUSH_CHANGES=false
SINGLE_REPO=""

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --push)
            PUSH_CHANGES=true
            ;;
        *)
            if [ -z "$SINGLE_REPO" ]; then
                SINGLE_REPO="$arg"
            fi
            ;;
    esac
done

echo "📚 Portfolio Documentation Rebuild Script"
echo "========================================"
echo ""
echo "Portfolio root: $PORTFOLIO_ROOT"
echo "Pages root: $PAGES_ROOT"
echo "Push changes: $PUSH_CHANGES"
[ -n "$SINGLE_REPO" ] && echo "Single repo mode: $SINGLE_REPO"
echo ""

# Array of repos with documentation
declare -a REPOS=(
    "chakraview-zero-trust-blueprint:zero-trust-blueprint"
    "chakraview-enterprise-modernization:enterprise-modernization"
    "chakraview-realtime-data-platform:realtime-data-platform"
    "chakraview-data-engineering-patterns:data-engineering-patterns"
    "chakraview-networking-sdn:networking-sdn"
)

# If single repo specified, validate and filter
if [ -n "$SINGLE_REPO" ]; then
    found=false
    for repo_config in "${REPOS[@]}"; do
        IFS=':' read -r repo_name output_dir <<< "$repo_config"
        if [ "$repo_name" = "$SINGLE_REPO" ] || [ "$output_dir" = "$SINGLE_REPO" ]; then
            REPOS=("$repo_config")
            found=true
            break
        fi
    done

    if [ "$found" = false ]; then
        echo "❌ Error: Repository '$SINGLE_REPO' not found"
        echo ""
        echo "Available repos:"
        for repo_config in "${REPOS[@]}"; do
            IFS=':' read -r repo_name output_dir <<< "$repo_config"
            echo "  - $repo_name (output: $output_dir)"
        done
        exit 1
    fi
fi

# Function to build docs for a repo
build_repo_docs() {
    local repo_name="$1"
    local output_dir="$2"
    local repo_path="$PORTFOLIO_ROOT/$repo_name"

    echo ""
    echo "🔨 Processing: $repo_name → $output_dir"
    echo "─────────────────────────────────────────"

    # Check if repo exists locally
    if [ ! -d "$repo_path" ]; then
        echo "  ❌ Repository not found at: $repo_path"
        return 1
    fi

    # Check if mkdocs.yml exists
    if [ ! -f "$repo_path/mkdocs.yml" ]; then
        echo "  ⏭️  No mkdocs.yml found, skipping"
        return 0
    fi

    # Check if docs directory exists
    if [ ! -d "$repo_path/docs" ]; then
        echo "  ⏭️  No docs directory found, skipping"
        return 0
    fi

    # Build mkdocs
    echo "  🏗️  Building mkdocs..."
    cd "$repo_path"

    # Ensure mkdocs is installed
    if ! python -m pip show mkdocs &>/dev/null; then
        echo "  📦 Installing mkdocs dependencies..."
        pip install mkdocs mkdocs-material pymdown-extensions -q
    fi

    # Remove old output directory if it exists
    rm -rf site

    # Build site
    if ! mkdocs build --quiet 2>/dev/null; then
        echo "  ❌ Build failed for $repo_name"
        return 1
    fi

    # Remove old docs in pages repo
    if [ -d "$PAGES_ROOT/$output_dir" ]; then
        echo "  🗑️  Removing old docs at /$output_dir"
        rm -rf "$PAGES_ROOT/$output_dir"
    fi

    # Copy built docs to pages repo
    mkdir -p "$PAGES_ROOT/$output_dir"
    cp -r site/* "$PAGES_ROOT/$output_dir/"

    echo "  ✅ Built and deployed to /$output_dir"
    return 0
}

# Build repos
FAILED_REPOS=()
for repo_config in "${REPOS[@]}"; do
    IFS=':' read -r repo_name output_dir <<< "$repo_config"

    if ! build_repo_docs "$repo_name" "$output_dir"; then
        FAILED_REPOS+=("$repo_name")
    fi
done

# Summary
echo ""
echo "📊 Build Summary"
echo "════════════════════════════════════════"

if [ ${#FAILED_REPOS[@]} -eq 0 ]; then
    echo "✅ Documentation built successfully!"
else
    echo "⚠️  Some repos failed to build:"
    for repo in "${FAILED_REPOS[@]}"; do
        echo "  - $repo"
    done
fi

# Git operations
cd "$PAGES_ROOT"

if [ $PUSH_CHANGES = true ]; then
    echo ""
    echo "📤 Git Operations"
    echo "════════════════════════════════════════"

    if [ -n "$(git status --porcelain)" ]; then
        echo "  📝 Staging changes..."
        git add -A

        if [ -n "$SINGLE_REPO" ]; then
            commit_msg="docs: rebuild $SINGLE_REPO documentation $(date '+%Y-%m-%d %H:%M:%S')"
        else
            commit_msg="docs: rebuild all portfolio documentation $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        echo "  💾 Committing with message: '$commit_msg'"
        git commit -m "$commit_msg"

        echo "  📤 Pushing to remote..."
        git push origin main

        echo "✅ Changes pushed to GitHub"
    else
        echo "  ℹ️  No changes to commit"
    fi
else
    echo ""
    echo "📋 Changes staged locally (use --push to commit and push)"
    echo ""
    echo "To review changes:"
    echo "  cd $PAGES_ROOT"
    echo "  git status"
    echo "  git diff --cached | less"
    echo ""
    echo "To commit and push:"
    if [ -n "$SINGLE_REPO" ]; then
        echo "  git commit -m 'docs: rebuild $SINGLE_REPO documentation'"
    else
        echo "  git commit -m 'docs: rebuild all portfolio documentation'"
    fi
    echo "  git push origin main"
fi

echo ""
echo "✨ Done!"

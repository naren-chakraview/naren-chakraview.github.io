#!/bin/bash

# Rebuild all portfolio project documentation
# Usage: ./scripts/rebuild-all-docs.sh [--push]
#
# This script:
# 1. Clones/pulls each portfolio repo
# 2. Builds mkdocs for repos with documentation
# 3. Updates the GitHub Pages repo with built docs
# 4. Optionally commits and pushes (with --push flag)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAGES_ROOT="$(dirname "$SCRIPT_DIR")"
WORK_DIR="${PAGES_ROOT}/.build-tmp"
PUSH_CHANGES=false
BASE_URL="https://github.com/naren-chakraview"

# Parse arguments
if [ "$1" = "--push" ]; then
    PUSH_CHANGES=true
fi

echo "📚 Portfolio Documentation Rebuild Script"
echo "========================================"
echo ""
echo "Pages root: $PAGES_ROOT"
echo "Work directory: $WORK_DIR"
echo "Push changes: $PUSH_CHANGES"
echo ""

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Array of repos with documentation
declare -a REPOS=(
    "chakraview-zero-trust-blueprint:zero-trust-blueprint"
    "chakraview-enterprise-modernization:enterprise-modernization"
    "chakraview-realtime-data-platform:realtime-data-platform"
    "chakraview-data-engineering-patterns:data-engineering-patterns"
    "chakraview-networking-sdn:networking-sdn"
)

# Function to build docs for a repo
build_repo_docs() {
    local repo_name="$1"
    local output_dir="$2"
    local full_path="$WORK_DIR/$repo_name"

    echo ""
    echo "🔨 Processing: $repo_name → $output_dir"
    echo "─────────────────────────────────────────"

    # Clone or pull repo
    if [ -d "$full_path" ]; then
        echo "  📥 Pulling updates..."
        cd "$full_path"
        git pull origin main --quiet
    else
        echo "  📥 Cloning repo..."
        git clone "$BASE_URL/$repo_name.git" "$full_path" --quiet
        cd "$full_path"
    fi

    # Check if mkdocs.yml exists
    if [ ! -f "mkdocs.yml" ]; then
        echo "  ⏭️  No mkdocs.yml found, skipping"
        return 0
    fi

    # Check if docs directory exists
    if [ ! -d "docs" ]; then
        echo "  ⏭️  No docs directory found, skipping"
        return 0
    fi

    # Build mkdocs
    echo "  🏗️  Building mkdocs..."
    if ! python -m pip show mkdocs &>/dev/null; then
        echo "  📦 Installing mkdocs dependencies..."
        pip install mkdocs mkdocs-material pymdown-extensions -q
    fi

    # Remove old output directory if it exists
    rm -rf site

    # Build site
    mkdocs build --quiet 2>/dev/null || {
        echo "  ❌ Build failed for $repo_name"
        return 1
    }

    # Remove old docs in pages repo
    if [ -d "$PAGES_ROOT/$output_dir" ]; then
        rm -rf "$PAGES_ROOT/$output_dir"
    fi

    # Copy built docs to pages repo
    mkdir -p "$PAGES_ROOT/$output_dir"
    cp -r site/* "$PAGES_ROOT/$output_dir/"

    echo "  ✅ Built and deployed to /$output_dir"
}

# Build each repo
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
    echo "✅ All documentation built successfully!"
else
    echo "⚠️  Some repos failed to build:"
    for repo in "${FAILED_REPOS[@]}"; do
        echo "  - $repo"
    done
fi

# Cleanup work directory
echo ""
echo "🧹 Cleaning up..."
cd "$PAGES_ROOT"
rm -rf "$WORK_DIR"

# Git operations
if [ $PUSH_CHANGES = true ]; then
    echo ""
    echo "📤 Git Operations"
    echo "════════════════════════════════════════"

    if [ -n "$(git status --porcelain)" ]; then
        echo "  📝 Staging changes..."
        git add -A

        echo "  💾 Committing..."
        git commit -m "docs: rebuild all portfolio documentation $(date '+%Y-%m-%d %H:%M:%S')"

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
    echo "  git status"
    echo "  git diff --cached"
    echo ""
    echo "To commit and push:"
    echo "  git add -A"
    echo "  git commit -m 'docs: rebuild all portfolio documentation'"
    echo "  git push origin main"
fi

echo ""
echo "✨ Done!"

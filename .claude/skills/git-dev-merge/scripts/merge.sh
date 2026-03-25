#!/bin/bash
# Git Dev Merge Script for Blured Engine
# Merges feature branches back to base branches across main repo + submodules
# Usage: merge.sh <feature-branch> [issue-number]

set -e

# Derive workspace root: this script lives at <workspace>/.claude/skills/git-dev-merge/scripts/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}→${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; }
header(){ echo -e "\n${BLUE}═══ $1 ═══${NC}"; }

FEATURE_BRANCH="$1"
ISSUE_NUMBER="$2"

if [ -z "$FEATURE_BRANCH" ]; then
    # Auto-detect from current branch
    cd "$ROOT"
    FEATURE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$FEATURE_BRANCH" = "main" ]; then
        error "Cannot merge: already on base branch '$FEATURE_BRANCH'. Provide a feature branch name."
        exit 1
    fi
    info "Auto-detected feature branch: $FEATURE_BRANCH"
fi

MERGED_REPOS=()
SKIPPED_REPOS=()

# --- Helper: merge a submodule feature branch into its base branch ---
merge_submodule() {
    local repo_path="$1"
    local repo_name="$2"
    local base_branch="$3"

    cd "$repo_path"
    header "$repo_name ($FEATURE_BRANCH → $base_branch)"

    git fetch origin

    # Check if feature branch exists on remote
    if ! git ls-remote --exit-code --heads origin "$FEATURE_BRANCH" >/dev/null 2>&1; then
        warn "$repo_name: branch '$FEATURE_BRANCH' not found on remote — skipping"
        SKIPPED_REPOS+=("$repo_name")
        return 0
    fi

    # Check if feature branch exists locally
    if ! git rev-parse --verify "$FEATURE_BRANCH" >/dev/null 2>&1; then
        git checkout -b "$FEATURE_BRANCH" "origin/$FEATURE_BRANCH"
    fi

    # Check if there are actual changes to merge
    local merge_base
    merge_base=$(git merge-base "$base_branch" "$FEATURE_BRANCH" 2>/dev/null || echo "")
    local feature_head
    feature_head=$(git rev-parse "$FEATURE_BRANCH" 2>/dev/null || echo "")
    local base_head
    base_head=$(git rev-parse "$base_branch" 2>/dev/null || echo "")

    if [ "$feature_head" = "$base_head" ] || [ "$feature_head" = "$merge_base" ]; then
        warn "$repo_name: no changes on '$FEATURE_BRANCH' relative to '$base_branch' — deleting branch only"
        git checkout "$base_branch"
        git branch -d "$FEATURE_BRANCH" 2>/dev/null || true
        git push origin --delete "$FEATURE_BRANCH" --no-verify 2>/dev/null || true
        SKIPPED_REPOS+=("$repo_name (no changes, branch deleted)")
        return 0
    fi

    # Merge
    git checkout "$base_branch"
    git pull origin "$base_branch"

    if ! git merge --no-ff "$FEATURE_BRANCH" -m "Merge $FEATURE_BRANCH into $base_branch"; then
        error "$repo_name: MERGE CONFLICT — resolve manually and re-run"
        exit 1
    fi

    git push --no-verify
    info "Merged and pushed $repo_name"

    # Delete feature branch (local + remote)
    git branch -d "$FEATURE_BRANCH"
    git push origin --delete "$FEATURE_BRANCH" --no-verify 2>/dev/null || true
    info "Deleted branch '$FEATURE_BRANCH' from $repo_name"

    MERGED_REPOS+=("$repo_name: $FEATURE_BRANCH → $base_branch")
}

# === 1. Merge submodules first ===
merge_submodule "$ROOT/godot" "godot" "main"
merge_submodule "$ROOT/opencode" "opencode" "main"

# === 2. Update main repo submodule refs ===
cd "$ROOT"

# Checkout submodules to their base branches so refs point to merged state
cd "$ROOT/godot" && git checkout main && git pull origin main 2>/dev/null
cd "$ROOT/opencode" && git checkout main && git pull origin main 2>/dev/null
cd "$ROOT"

# Stage submodule ref updates if they changed
if ! git diff --quiet godot opencode 2>/dev/null; then
    header "Submodule refs"
    git add godot opencode
    git commit -m "chore: update submodule refs after feature merge"
    info "Updated submodule refs"
fi

# === 3. Merge main repo ===
header "blured-engine ($FEATURE_BRANCH → main)"

git fetch origin

MERGE_MSG="Merge $FEATURE_BRANCH into main"
if [ -n "$ISSUE_NUMBER" ]; then
    MERGE_MSG="$MERGE_MSG

Closes #$ISSUE_NUMBER"
fi

git checkout main
git pull origin main

if ! git merge --no-ff "$FEATURE_BRANCH" -m "$MERGE_MSG"; then
    error "blured-engine: MERGE CONFLICT — resolve manually and re-run"
    exit 1
fi

git push
info "Merged and pushed blured-engine"

# Delete feature branch (local + remote)
git branch -d "$FEATURE_BRANCH"
git push origin --delete "$FEATURE_BRANCH" 2>/dev/null || true
info "Deleted branch '$FEATURE_BRANCH' from blured-engine"

MERGED_REPOS+=("blured-engine: $FEATURE_BRANCH → main")

# === 4. Close issue if provided ===
if [ -n "$ISSUE_NUMBER" ]; then
    header "Issue #$ISSUE_NUMBER"
    gh issue close "$ISSUE_NUMBER" --repo bluredengine/blured --comment "Closed via merge of $FEATURE_BRANCH" 2>/dev/null || warn "Could not close issue #$ISSUE_NUMBER"
    info "Issue #$ISSUE_NUMBER closed"
fi

# === Summary ===
echo ""
header "Merge Summary"
echo ""
if [ -n "$ISSUE_NUMBER" ]; then
    info "Issue: #$ISSUE_NUMBER"
fi
info "Branch: $FEATURE_BRANCH"
echo ""

if [ ${#MERGED_REPOS[@]} -gt 0 ]; then
    echo -e "${GREEN}Merged:${NC}"
    for repo in "${MERGED_REPOS[@]}"; do
        echo -e "  ${GREEN}→${NC} $repo"
    done
fi

if [ ${#SKIPPED_REPOS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Skipped:${NC}"
    for repo in "${SKIPPED_REPOS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $repo"
    done
fi

echo ""
info "Feature branches deleted from all repos."

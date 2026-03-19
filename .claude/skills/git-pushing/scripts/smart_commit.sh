#!/bin/bash
# Smart Git Commit Script for Blured Engine
# Handles main repo + godot/ and opencode/ submodules

set -e

# Derive workspace root: this script lives at <workspace>/.claude/skills/git-pushing/scripts/
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

CUSTOM_MSG="$1"
PUSHED_REPOS=()

# --- Helper: commit and push a single repo ---
commit_and_push() {
    local repo_path="$1"
    local repo_name="$2"

    cd "$repo_path"

    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)

    # Check for changes (staged + unstaged + untracked)
    if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        info "$repo_name: no changes"
        return 0
    fi

    header "$repo_name ($branch)"

    # Stage all changes
    git add -A
    local staged_files
    staged_files=$(git diff --cached --name-only)
    local diff_stat
    diff_stat=$(git diff --cached --stat)

    if [ -z "$staged_files" ]; then
        info "$repo_name: nothing to commit after staging"
        return 0
    fi

    # Build commit message
    local commit_msg
    if [ -n "$CUSTOM_MSG" ]; then
        commit_msg="$CUSTOM_MSG"
    else
        local num_files
        num_files=$(echo "$staged_files" | wc -l | xargs)

        # Auto-detect commit type
        local commit_type="feat"
        if echo "$staged_files" | grep -qE "\.(md|txt)$" && [ "$num_files" -le 3 ]; then
            commit_type="docs"
        elif echo "$staged_files" | grep -qE "package\.json|bun\.lock"; then
            commit_type="chore"
        elif echo "$staged_files" | grep -q "test"; then
            commit_type="test"
        fi

        # Auto-detect scope from common directories
        local scope=""
        if echo "$staged_files" | grep -q "editor/plugins/ai_assistant"; then
            scope="ai-assistant"
        elif echo "$staged_files" | grep -q "modules/godot_ai"; then
            scope="godot-ai"
        elif echo "$staged_files" | grep -q "plugin"; then
            scope="plugin"
        elif echo "$staged_files" | grep -q "skill"; then
            scope="skill"
        elif echo "$staged_files" | grep -q "docs"; then
            scope="docs"
        fi

        if [ -n "$scope" ]; then
            commit_msg="${commit_type}(${scope}): update ${num_files} file(s)"
        else
            commit_msg="${commit_type}: update ${num_files} file(s)"
        fi
    fi

    info "Commit: $commit_msg"

    git commit -m "${commit_msg}"

    local commit_hash
    commit_hash=$(git rev-parse --short HEAD)
    info "Created commit: $commit_hash"

    # Push (--no-verify to skip upstream hooks on forks)
    if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        git push --no-verify
    else
        git push -u origin "$branch" --no-verify
    fi

    info "Pushed $repo_name to origin/$branch"
    echo "$diff_stat"
    PUSHED_REPOS+=("$repo_name ($branch) $commit_hash")
}

# === 1. Submodules first ===
commit_and_push "$ROOT/godot" "godot"
commit_and_push "$ROOT/opencode" "opencode"

# === 2. Main repo (includes submodule ref updates) ===
commit_and_push "$ROOT" "blured-engine"

# === Summary ===
echo ""
if [ ${#PUSHED_REPOS[@]} -eq 0 ]; then
    warn "Nothing to push across all repos."
else
    header "Push Summary"
    for repo in "${PUSHED_REPOS[@]}"; do
        info "$repo"
    done
fi

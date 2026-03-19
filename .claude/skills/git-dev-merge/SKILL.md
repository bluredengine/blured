---
name: git-dev-merge
description: Merge feature branches back to their base branches across the main repo and submodules. Use when user says "merge feature", "finish feature", "merge back", or invokes /git-dev-merge.
---

# Git Dev Merge

Merge feature branches back to their base branches across the main repo and submodules.

## Repository Layout

- **Main repo**: `origin` → `github.com:bluredengine/blured.git`, base branch `main`
- **godot/** submodule: `origin` → `github.com:bluredengine/godot.git`, base branch `main`
- **opencode/** submodule: `origin` → `github.com:bluredengine/opencode.git`, base branch `main`

The script auto-detects the workspace root from its own location.

## Workflow

**ALWAYS use the script (from any workspace):**

```bash
bash "<workspace>/.claude/skills/git-dev-merge/scripts/merge.sh" "<feature-branch>" "<issue-number>"
```

Both arguments are optional:
- If `<feature-branch>` is omitted, auto-detects from the current branch in the main repo
- If `<issue-number>` is omitted, no issue is closed

### Examples

```bash
# Auto-detect branch, no issue
bash "<workspace>/.claude/skills/git-dev-merge/scripts/merge.sh"

# Explicit branch and issue
bash "<workspace>/.claude/skills/git-dev-merge/scripts/merge.sh" "feature/7-ai-mesh-generation" "7"
```

## What the Script Does

1. **Pushes pending changes first** — use `/git-pushing` before running this if there are uncommitted changes
2. **Merges godot/** submodule: `feature/<branch>` → `main`, deletes feature branch
3. **Merges opencode/** submodule: `feature/<branch>` → `main`, deletes feature branch
4. **Updates submodule refs** in the main repo
5. **Merges main repo**: `feature/<branch>` → `main`, deletes feature branch
6. **Closes the GitHub issue** (if issue number provided)
7. **Shows merge summary**

## Post-Merge Cleanup

After running the script, also:
1. Remove the "Current Work Session" section from `CLAUDE.local.md` if it exists
2. Report the merge summary to the user

## Handling Conflicts

- If a merge conflict occurs in any repo, the script **stops and reports the error**
- Do NOT force merge or discard changes
- Let the user resolve manually, then re-run

## Important Rules

1. Always merge submodules BEFORE the main repo
2. Use `--no-ff` to preserve merge history
3. Use `--no-verify` when pushing submodules (upstream hooks may fail on forks)
4. Delete feature branches from both local and remote after merge
5. If a submodule feature branch has no changes, just delete it (no merge needed)
6. Push any uncommitted work before starting the merge process

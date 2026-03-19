---
name: git-pushing
description: Stage, commit, and push git changes with conventional commit messages. Use when user wants to commit and push changes, mentions pushing to remote, or asks to save and push their work. Also activates when user says "push changes", "commit and push", "push this", "push to github", or similar git workflow requests.
---

# Git Push Workflow

Stage, commit, and push changes across the Blured Engine repo and its submodules.

## Repository Layout

- **Main repo**: `origin` → `github.com:bluredengine/blured.git`
- **godot/** submodule: `origin` → `github.com:bluredengine/godot.git`
- **opencode/** submodule: `origin` → `github.com:bluredengine/opencode.git`

The script auto-detects the workspace root from its own location.

## Workflow

**ALWAYS use the script (from any workspace):**

```bash
bash "<workspace>/.claude/skills/git-pushing/scripts/smart_commit.sh"
```

With custom message (applied to all repos that have changes):
```bash
bash "<workspace>/.claude/skills/git-pushing/scripts/smart_commit.sh" "feat: add feature"
```

## What the Script Does

1. Commits and pushes **godot/** submodule changes (if any)
2. Commits and pushes **opencode/** submodule changes (if any)
3. Stages submodule ref updates + main repo changes, commits and pushes **blured-engine**
4. Uses `--no-verify` for submodule pushes (upstream hooks may fail on our fork)
5. Shows summary of all repos pushed

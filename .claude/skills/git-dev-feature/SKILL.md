# git-dev-feature

Start a new feature development workflow by creating an issue and feature branches across the main repo and submodules.

## Invocation

User-invocable skill. Triggers when:
- User says `/git-dev-feature <description>`
- User says "start feature", "new feature", "implement feature"

## Parameters

Takes a sentence describing the feature to implement.

Example:
```
/git-dev-feature add dark mode toggle to settings page
```

## Repository Layout

- **Main repo** (`g:/blured-engine`): `origin` → `github.com:bluredengine/blured.git`, base branch `master`
- **godot/** submodule: `origin` → `github.com:bluredengine/godot.git`, base branch `blured`
- **opencode/** submodule: `origin` → `github.com:bluredengine/opencode.git`, base branch `blured`

## Workflow

### Step 1: Create GitHub Issues

Create a new issue on **each repo** (main repo + submodules). Each repo gets its own issue with cross-references.

#### 1a. Main repo issue

```bash
cd "g:/blured-engine"
gh issue create --title "<description>" --body "## Description

<description>

## Related Issues

- godot: bluredengine/godot#<godot-issue-number>
- opencode: bluredengine/opencode#<opencode-issue-number>

## Created by

git-dev-feature skill

## Status

- [ ] Implementation in progress
"
```

#### 1b. godot submodule issue

```bash
cd "g:/blured-engine/godot"
gh issue create --title "<description>" --body "## Description

<description>

## Related Issues

- blured-engine: bluredengine/blured#<main-issue-number>
- opencode: bluredengine/opencode#<opencode-issue-number>

## Created by

git-dev-feature skill

## Status

- [ ] Implementation in progress
"
```

#### 1c. opencode submodule issue

```bash
cd "g:/blured-engine/opencode"
gh issue create --title "<description>" --body "## Description

<description>

## Related Issues

- blured-engine: bluredengine/blured#<main-issue-number>
- opencode: bluredengine/opencode#<opencode-issue-number>

## Created by

git-dev-feature skill

## Status

- [ ] Implementation in progress
"
```

**Note**: Create all 3 issues first, then go back and update their bodies with the correct cross-reference issue numbers.

### Step 2: Create Feature Branches

Use the **main repo issue number** in the branch name across all three repos. Create from each repo's base branch.

Branch naming: `feature/<main-issue-number>-<short-slug>` (e.g. `feature/58-add-dark-mode-toggle`)

#### 2a. Main repo (from `master`)

```bash
cd "g:/blured-engine"
git fetch origin
git checkout master
git pull origin master
git checkout -b feature/<main-issue-number>-<slug>
git push -u origin feature/<main-issue-number>-<slug>
```

#### 2b. godot submodule (from `blured`)

```bash
cd "g:/blured-engine/godot"
git fetch origin
git checkout blured
git pull origin blured
git checkout -b feature/<main-issue-number>-<slug>
git push -u origin feature/<main-issue-number>-<slug> --no-verify
```

#### 2c. opencode submodule (from `blured`)

```bash
cd "g:/blured-engine/opencode"
git fetch origin
git checkout blured
git pull origin blured
git checkout -b feature/<main-issue-number>-<slug>
git push -u origin feature/<main-issue-number>-<slug> --no-verify
```

### Step 3: Overwrite CLAUDE.local.md

Overwrite the current workspace status to CLAUDE.local.md:

```markdown
## Current Work Session

**Issue**: #<main-issue-number> - <description>
**Branch**: feature/<main-issue-number>-<slug>
**Started**: <timestamp>
**Status**: In Progress

### Repos
| Repo | Base Branch | Feature Branch | Issue |
|------|-------------|----------------|-------|
| blured-engine | master | feature/<main-issue-number>-<slug> | #<main-issue-number> |
| godot | blured | feature/<main-issue-number>-<slug> | bluredengine/godot#<godot-issue-number> |
| opencode | blured | feature/<main-issue-number>-<slug> | bluredengine/opencode#<opencode-issue-number> |

---

```

If CLAUDE.local.md doesn't exist, create it with this content.

### Step 4: Confirm to User

Output:
```
Created issues:
  blured-engine: #<main-issue-number>
  godot:           bluredengine/godot#<godot-issue-number>
  opencode:        bluredengine/opencode#<opencode-issue-number>

Branch: feature/<main-issue-number>-<slug> (created in all 3 repos)

  blured-engine: master  → feature/<main-issue-number>-<slug>
  godot:           blured → feature/<main-issue-number>-<slug>
  opencode:        blured → feature/<main-issue-number>-<slug>

Workspace logged in CLAUDE.local.md

Ready to implement! When done, use /git-dev-merge to merge back.
```

## Important Rules

1. Always fetch and pull base branches before creating feature branches
2. Use lowercase and hyphens for branch slug
3. Keep branch name under 50 characters
4. Use `--no-verify` when pushing submodules (upstream hooks may fail on forks)
5. Create an issue on **each repo** (main + submodules) with cross-references between them
6. Use the **main repo issue number** in the branch name across all three repos for consistency
7. Don't start implementation — just set up the workspace
8. If a submodule has no changes expected, still create the branch (can be deleted later)

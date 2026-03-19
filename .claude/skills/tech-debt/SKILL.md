---
name: tech-debt
description: Clean up tech debt - remove obsolete files, temporary files, unused code, dead imports, and other cruft. Use when user wants to clean up the codebase, remove unused code, or reduce tech debt.
---

# Tech Debt Cleanup

Analyze and clean up technical debt in the codebase.

## When to Use

Activate when the user:
- Asks to clean up tech debt or cruft
- Wants to remove unused code or files
- Mentions removing temporary or obsolete files
- Says "cleanup", "remove dead code", "find unused"

## Cleanup Categories

### 1. Obsolete & Temporary Files

Search for and remove:
```bash
# Find temp files (includes Claude Code temp files)
find . -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*.orig" -o -name "*~" -o -name "*.swp" -o -name "tmpclaude-*" \) -not -path "*/node_modules/*" -not -path "*/.git/*"

# Find empty directories
find . -type d -empty -not -path "*/node_modules/*" -not -path "*/.git/*"

# Find log files outside proper locations
find . -type f -name "*.log" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/logs/*"
```

### 2. Unused Dependencies

Check package.json files:
```bash
# List all package.json files
find . -name "package.json" -not -path "*/node_modules/*"
```

For each package.json, use `npx depcheck` to find:
- Unused dependencies
- Missing dependencies
- Unused devDependencies

### 3. Dead Code Patterns

Search for common dead code patterns:

```bash
# Commented-out code blocks (multiple consecutive comment lines)
grep -rn "^[[:space:]]*//.*[;{}()]" --include="*.ts" --include="*.tsx" --include="*.js" | head -50

# TODO/FIXME comments older than expected
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" --include="*.js" | head -30

# Unused exports (search for exports never imported elsewhere)
# This requires cross-referencing - use the Task agent for thorough analysis
```

### 4. TypeScript-Specific

```bash
# Find files with 'any' type (potential tech debt)
grep -rn ": any" --include="*.ts" --include="*.tsx" | wc -l

# Find @ts-ignore comments
grep -rn "@ts-ignore\|@ts-nocheck" --include="*.ts" --include="*.tsx"

# Find eslint-disable comments
grep -rn "eslint-disable" --include="*.ts" --include="*.tsx" --include="*.js"
```

### 5. Obsolete Build Directories

Detect leftover directories from old project structures that only contain build artifacts:

```bash
# Find root-level directories that only contain dist/ or node_modules/
# These are likely leftovers from pre-monorepo structure
for dir in */; do
  if [ -d "$dir" ] && [ ! -f "${dir}package.json" ] && [ ! -f "${dir}README.md" ]; then
    contents=$(ls -A "$dir" 2>/dev/null)
    if [[ "$contents" == "dist" ]] || [[ "$contents" == "node_modules" ]] || [[ "$contents" == $'dist\nnode_modules' ]]; then
      echo "Obsolete: $dir (only contains: $contents)"
    fi
  fi
done
```

### 6. Duplicate Code

Use the Task agent with Explore subagent to find:
- Similar function implementations across files
- Copy-pasted code blocks
- Functions that could be consolidated

## Workflow

**ALWAYS use the scripts** - do NOT use manual commands:

### Step 1: Scan (Read-Only)

Run the scan script to generate a report:

```bash
bash .claude/skills/tech-debt/scripts/scan.sh
```

### Step 2: Review with User

Present findings in categories:
- **Safe to remove**: Temp files, empty dirs, obvious cruft
- **Needs review**: Potentially unused code, commented blocks
- **Dependencies**: Unused npm packages

### Step 3: Execute Cleanup (With Approval)

Only proceed with user approval. Use the cleanup script:

```bash
# Remove temp files
bash .claude/skills/tech-debt/scripts/cleanup.sh temp-files

# Remove empty directories
bash .claude/skills/tech-debt/scripts/cleanup.sh empty-dirs

# Remove stray log files
bash .claude/skills/tech-debt/scripts/cleanup.sh log-files

# List files with @ts-ignore (for review)
bash .claude/skills/tech-debt/scripts/cleanup.sh list-ts-ignore

# List TODO/FIXME comments
bash .claude/skills/tech-debt/scripts/cleanup.sh list-todos

# Run depcheck on a workspace
bash .claude/skills/tech-debt/scripts/cleanup.sh depcheck packages/game-engine/server

# Remove obsolete build directories (leftovers from old structure)
bash .claude/skills/tech-debt/scripts/cleanup.sh obsolete-dirs
```

## Important Rules

1. **NEVER auto-delete** - Always show findings first and get user approval
2. **Skip node_modules and .git** - These are managed separately
3. **Be conservative** - When in doubt, flag for review rather than auto-remove
4. **Preserve git history** - Don't use git filter-branch unless explicitly asked
5. **Check before removing** - Verify files aren't imported/used elsewhere
6. **Create backup list** - Before bulk deletions, list what will be removed

## Example Report Format

```
📊 TECH DEBT ANALYSIS REPORT
============================

🗑️ TEMPORARY FILES (3 found)
   - ./tmp/debug.log (2.1KB)
   - ./packages/game-engine/test.bak (500B)
   - ./notes.tmp (1.2KB)

📦 UNUSED DEPENDENCIES
   game-engine/server:
   - lodash (unused)
   - moment (unused, consider date-fns)

   platform/web:
   - @types/react-dom (duplicate of built-in)

💀 DEAD CODE INDICATORS
   - 15 files with @ts-ignore
   - 8 TODO comments older than 30 days
   - 3 commented-out code blocks (50+ lines each)

🎯 RECOMMENDED ACTIONS
   1. [SAFE] Remove 3 temp files
   2. [REVIEW] Check 15 @ts-ignore usages
   3. [DEPS] Remove 3 unused dependencies

Proceed with cleanup? (specify categories or 'all')
```

## Integration with Other Skills

- After cleanup, use `/push` to commit changes
- For dependency updates, consider `/release` workflow
- For large refactors found during cleanup, create separate tasks

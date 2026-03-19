#!/bin/bash
# Tech Debt Scanner
# Scans the codebase for common tech debt indicators

set -e

echo "📊 TECH DEBT ANALYSIS REPORT"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Temporary Files
echo -e "${YELLOW}🗑️  TEMPORARY FILES${NC}"
TEMP_FILES=$(find . -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*.orig" -o -name "*~" -o -name "*.swp" -o -name "*.swo" -o -name "tmpclaude-*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)
if [ -n "$TEMP_FILES" ]; then
    echo "$TEMP_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            SIZE=$(du -h "$file" 2>/dev/null | cut -f1)
            echo "   - $file ($SIZE)"
        fi
    done
else
    echo "   ✓ No temporary files found"
fi
echo ""

# 2. Empty Directories
echo -e "${YELLOW}📁 EMPTY DIRECTORIES${NC}"
EMPTY_DIRS=$(find . -type d -empty -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)
if [ -n "$EMPTY_DIRS" ]; then
    echo "$EMPTY_DIRS" | head -10
    COUNT=$(echo "$EMPTY_DIRS" | wc -l)
    if [ "$COUNT" -gt 10 ]; then
        echo "   ... and $((COUNT - 10)) more"
    fi
else
    echo "   ✓ No empty directories found"
fi
echo ""

# 3. Log Files Outside Logs Directory
echo -e "${YELLOW}📝 STRAY LOG FILES${NC}"
LOG_FILES=$(find . -type f -name "*.log" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/logs/*" -not -path "*/.next/*" 2>/dev/null || true)
if [ -n "$LOG_FILES" ]; then
    echo "$LOG_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            SIZE=$(du -h "$file" 2>/dev/null | cut -f1)
            echo "   - $file ($SIZE)"
        fi
    done
else
    echo "   ✓ No stray log files found"
fi
echo ""

# 4. TypeScript Tech Debt Indicators
echo -e "${YELLOW}💀 CODE QUALITY INDICATORS${NC}"

# @ts-ignore count
TS_IGNORE=$(grep -rn "@ts-ignore\|@ts-nocheck" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l || echo "0")
echo "   @ts-ignore/@ts-nocheck: $TS_IGNORE occurrences"

# eslint-disable count
ESLINT_DISABLE=$(grep -rn "eslint-disable" --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | wc -l || echo "0")
echo "   eslint-disable: $ESLINT_DISABLE occurrences"

# 'any' type count
ANY_TYPE=$(grep -rn ": any\b" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l || echo "0")
echo "   Explicit 'any' types: $ANY_TYPE occurrences"

# TODO/FIXME count
TODOS=$(grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | wc -l || echo "0")
echo "   TODO/FIXME comments: $TODOS occurrences"
echo ""

# 5. Obsolete Build Directories
echo -e "${YELLOW}🗂️  OBSOLETE BUILD DIRECTORIES${NC}"
OBSOLETE_FOUND=0
for dir in */; do
    if [ -d "$dir" ] && [ ! -f "${dir}package.json" ] && [ ! -f "${dir}README.md" ] && [ ! -f "${dir}SKILL.md" ]; then
        # Skip known valid directories
        case "$dir" in
            node_modules/|.git/|.claude/|packages/|infrastructure/|skills/|docs/) continue ;;
        esac
        contents=$(ls -A "$dir" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
        # Check if only contains dist, node_modules, or both
        if [[ "$contents" == "dist" ]] || [[ "$contents" == "node_modules" ]] || [[ "$contents" == "dist node_modules" ]] || [[ "$contents" == "node_modules dist" ]]; then
            echo "   - $dir (contains only: $contents)"
            OBSOLETE_FOUND=1
        fi
    fi
done
if [ "$OBSOLETE_FOUND" -eq 0 ]; then
    echo "   ✓ No obsolete build directories found"
fi
echo ""

# 6. Large Files in Git
echo -e "${YELLOW}📦 LARGE FILES IN GIT (top 10)${NC}"
git ls-files 2>/dev/null | head -100 | xargs -I{} git ls-tree -r -l HEAD -- {} 2>/dev/null | sort -k4 -n -r | head -10 | while read -r mode type hash size file; do
    if [ "$size" -gt 100000 ]; then
        SIZE_KB=$((size / 1024))
        echo "   - $file (${SIZE_KB}KB)"
    fi
done || echo "   ✓ No unusually large files found"
echo ""

# 7. Package.json locations
echo -e "${YELLOW}📋 PACKAGE.JSON FILES (for depcheck)${NC}"
find . -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | while read -r pkg; do
    echo "   - $pkg"
done
echo ""
echo "   Run 'npx depcheck <path>' on each to find unused dependencies"
echo ""

# Summary
echo "============================"
echo -e "${BLUE}📊 SUMMARY${NC}"
echo "   Temp files to review: $(echo "$TEMP_FILES" | grep -c . 2>/dev/null || echo "0")"
echo "   Code quality issues: $((TS_IGNORE + ESLINT_DISABLE + ANY_TYPE))"
echo "   TODOs to address: $TODOS"
echo ""
echo "Run specific cleanup commands after reviewing the findings above."

#!/bin/bash
# Tech Debt Cleanup Script
# Run specific cleanup actions after reviewing scan results

set -e

ACTION=$1

case $ACTION in
    "temp-files")
        echo "🗑️  Removing temporary files..."
        find . -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*.orig" -o -name "*~" -o -name "*.swp" -o -name "*.swo" -o -name "tmpclaude-*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -delete 2>/dev/null || true
        echo "✓ Done"
        ;;

    "empty-dirs")
        echo "📁 Removing empty directories..."
        find . -type d -empty -not -path "*/node_modules/*" -not -path "*/.git/*" -delete 2>/dev/null || true
        echo "✓ Done"
        ;;

    "log-files")
        echo "📝 Removing stray log files..."
        find . -type f -name "*.log" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/logs/*" -not -path "*/.next/*" -delete 2>/dev/null || true
        echo "✓ Done"
        ;;

    "list-ts-ignore")
        echo "💀 Files with @ts-ignore:"
        grep -rln "@ts-ignore\|@ts-nocheck" --include="*.ts" --include="*.tsx" 2>/dev/null | sort -u || echo "None found"
        ;;

    "list-eslint-disable")
        echo "💀 Files with eslint-disable:"
        grep -rln "eslint-disable" --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | sort -u || echo "None found"
        ;;

    "list-any-types")
        echo "💀 Files with explicit 'any' types:"
        grep -rln ": any\b" --include="*.ts" --include="*.tsx" 2>/dev/null | sort -u || echo "None found"
        ;;

    "list-todos")
        echo "📝 TODO/FIXME comments:"
        grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | head -50 || echo "None found"
        ;;

    "depcheck")
        WORKSPACE=$2
        if [ -z "$WORKSPACE" ]; then
            echo "Usage: cleanup.sh depcheck <workspace-path>"
            echo "Example: cleanup.sh depcheck packages/game-engine/server"
            exit 1
        fi
        echo "📦 Running depcheck on $WORKSPACE..."
        cd "$WORKSPACE" && npx depcheck . 2>/dev/null || echo "depcheck not available, install with: npm install -g depcheck"
        ;;

    "obsolete-dirs")
        echo "🗂️  Removing obsolete build directories..."
        for dir in */; do
            if [ -d "$dir" ] && [ ! -f "${dir}package.json" ] && [ ! -f "${dir}README.md" ] && [ ! -f "${dir}SKILL.md" ]; then
                case "$dir" in
                    node_modules/|.git/|.claude/|packages/|infrastructure/|skills/|docs/) continue ;;
                esac
                contents=$(ls -A "$dir" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
                if [[ "$contents" == "dist" ]] || [[ "$contents" == "node_modules" ]] || [[ "$contents" == "dist node_modules" ]] || [[ "$contents" == "node_modules dist" ]]; then
                    echo "   Removing: $dir"
                    rm -rf "$dir"
                fi
            fi
        done
        echo "✓ Done"
        ;;

    *)
        echo "Tech Debt Cleanup Script"
        echo "========================"
        echo ""
        echo "Usage: cleanup.sh <action> [options]"
        echo ""
        echo "Actions:"
        echo "  temp-files        Remove all temporary files (*.tmp, *.bak, tmpclaude-*, etc.)"
        echo "  empty-dirs        Remove all empty directories"
        echo "  log-files         Remove stray log files"
        echo "  list-ts-ignore    List files with @ts-ignore"
        echo "  list-eslint-disable List files with eslint-disable"
        echo "  list-any-types    List files with explicit 'any' types"
        echo "  list-todos        List TODO/FIXME comments"
        echo "  depcheck <path>   Run depcheck on a workspace"
        echo "  obsolete-dirs     Remove obsolete build directories (dist/node_modules only)"
        echo ""
        echo "Example:"
        echo "  cleanup.sh temp-files"
        echo "  cleanup.sh depcheck packages/game-engine/server"
        ;;
esac

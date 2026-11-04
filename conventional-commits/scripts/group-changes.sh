#!/bin/bash

# group-changes.sh
# Analyzes git changes and groups them into logical commits following Conventional Commits
# Part of the conventional-commits skill
#
# Usage: ./group-changes.sh [--staged|--all] [--json]
#
# Options:
#   --staged    Only analyze staged changes (default: all changes)
#   --json      Output in JSON format (default: human-readable)

set -e

# Determine mode
MODE="all"
OUTPUT_FORMAT="text"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --staged)
            MODE="staged"
            shift
            ;;
        --all)
            MODE="all"
            shift
            ;;
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository" >&2
    exit 1
fi

# Get changed files
if [ "$MODE" = "staged" ]; then
    # Only staged changes
    CHANGED_FILES=$(git diff --cached --name-only --diff-filter=d | grep -v '^$' || true)
    NEW_FILES=$(git diff --cached --name-only --diff-filter=A | grep -v '^$' || true)
    DELETED_FILES=$(git diff --cached --name-only --diff-filter=D | grep -v '^$' || true)
else
    # All changes (staged + unstaged + untracked)
    CHANGED_FILES=$(git diff --name-only --diff-filter=d | grep -v '^$' || true)
    STAGED_CHANGED=$(git diff --cached --name-only --diff-filter=d | grep -v '^$' || true)
    NEW_FILES=$(git diff --name-only --diff-filter=A | grep -v '^$' || true)
    STAGED_NEW=$(git diff --cached --name-only --diff-filter=A | grep -v '^$' || true)
    UNTRACKED=$(git ls-files --others --exclude-standard | grep -v '^$' || true)
    DELETED_FILES=$(git diff --name-only --diff-filter=D | grep -v '^$' || true)
    STAGED_DELETED=$(git diff --cached --name-only --diff-filter=D | grep -v '^$' || true)
    
    # Combine all
    CHANGED_FILES="$CHANGED_FILES $STAGED_CHANGED"
    NEW_FILES="$NEW_FILES $STAGED_NEW $UNTRACKED"
    DELETED_FILES="$DELETED_FILES $STAGED_DELETED"
fi

# Combine all files
ALL_FILES="$CHANGED_FILES $NEW_FILES $DELETED_FILES"

# Remove duplicates and empty strings
ALL_FILES=$(echo "$ALL_FILES" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')

# If no files, exit
if [ -z "$ALL_FILES" ]; then
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        echo '{"groups": []}'
    else
        echo "No changes found."
    fi
    exit 0
fi

# Initialize grouping variables
declare -A FEAT_FILES
declare -A FIX_FILES
declare -A DOCS_FILES
declare -A TEST_FILES
declare -A CHORE_FILES
declare -A REFACTOR_FILES
declare -A PERF_FILES
declare -A STYLE_FILES
declare -A REVERT_FILES
declare -A OTHER_FILES

declare -A FILE_STATUS

# Track all files
ALL_FILES_ARRAY=($ALL_FILES)

# Function to determine file type
get_file_type() {
    local file="$1"
    local filename=$(basename "$file")
    local ext="${filename##*.}"
    ext=${ext,,}  # lowercase
    
    # Check by filename pattern first
    case "$filename" in
        *.test.*|*.spec.*)
            echo "test"
            return
            ;;
        package*.json|*.lock|yarn.lock|pnpm-lock.yaml)
            echo "chore"
            return
            ;;
        *.eslintrc*|*.prettierrc*|.babelrc*|.gitignore|*.config.*|Makefile|Dockerfile*)
            echo "chore"
            return
            ;;
    esac
    
    # Check by extension
    case "$ext" in
        md|markdown)
            echo "docs"
            return
            ;;
        json|yaml|yml|toml|rc|config)
            echo "chore"
            return
            ;;
        css|scss|sass|less|styl)
            echo "style"
            return
            ;;
        test|spec)
            echo "test"
            return
            ;;
        ts|tsx|js|jsx|py|go|java|rb|php|rs|cpp|h|c|hs|kt|swift)
            echo "source"
            return
            ;;
        *)
            echo "other"
            return
            ;;
    esac
}

# Function to extract scope from path
get_scope() {
    local file="$1"
    
    # Remove leading ./
    file=${file#./}
    
    # Common scope patterns
    case "$file" in
        src/api/*)
            echo "api"
            return
            ;;
        src/components/*)
            echo "components"
            return
            ;;
        src/utils/*)
            echo "utils"
            return
            ;;
        src/services/*)
            echo "services"
            return
            ;;
        src/lib/*)
            echo "lib"
            return
            ;;
        src/models/*)
            echo "models"
            return
            ;;
        src/hooks/*)
            echo "hooks"
            return
            ;;
        src/store/*)
            echo "store"
            return
            ;;
        tests/*|test/*)
            echo "tests"
            return
            ;;
        docs/*|doc/*)
            echo "docs"
            return
            ;;
        *)
            # Use first directory as scope
            local first_dir=$(echo "$file" | cut -d'/' -f1)
            if [ -n "$first_dir" ] && [ "$first_dir" != "." ]; then
                echo "$first_dir"
            else
                echo ""
            fi
            return
            ;;
    esac
}

# Function to determine if file is new
is_new_file() {
    local file="$1"
    for f in ${NEW_FILES}; do
        if [ "$f" = "$file" ]; then
            echo "true"
            return
        fi
    done
    for f in ${UNTRACKED:-}; do
        if [ "$f" = "$file" ]; then
            echo "true"
            return
        fi
    done
    echo "false"
}

# Process each file
for file in "${ALL_FILES_ARRAY[@]}"; do
    [ -z "$file" ] && continue
    
    file_type=$(get_file_type "$file")
    scope=$(get_scope "$file")
    is_new=$(is_new_file "$file")
    
    # For source files, determine type based on whether it's new
    if [ "$file_type" = "source" ]; then
        if [ "$is_new" = "true" ]; then
            file_type="feat"
        else
            # Check if it's a refactor by looking at diff
            DIFF_OUTPUT=$(git diff --cached -- "$file" 2>/dev/null || git diff -- "$file" 2>/dev/null || echo "")
            if echo "$DIFF_OUTPUT" | grep -qiE "refactor|cleanup|restructure|reorganize"; then
                file_type="refactor"
            elif echo "$DIFF_OUTPUT" | grep -qiE "perf|performance|optimize"; then
                file_type="perf"
            elif echo "$DIFF_OUTPUT" | grep -qiE "fix|bug|patch"; then
                file_type="fix"
            else
                file_type="feat"
            fi
        fi
    fi
    
    # Map to group
    case "$file_type" in
        feat)
            if [ -n "$scope" ]; then
                FEAT_FILES["$scope"]="${FEAT_FILES[$scope]} $file"
            else
                FEAT_FILES["general"]="${FEAT_FILES[general]} $file"
            fi
            ;;
        fix)
            if [ -n "$scope" ]; then
                FIX_FILES["$scope"]="${FIX_FILES[$scope]} $file"
            else
                FIX_FILES["general"]="${FIX_FILES[general]} $file"
            fi
            ;;
        docs)
            if [ -n "$scope" ]; then
                DOCS_FILES["$scope"]="${DOCS_FILES[$scope]} $file"
            else
                DOCS_FILES["general"]="${DOCS_FILES[general]} $file"
            fi
            ;;
        test)
            if [ -n "$scope" ]; then
                TEST_FILES["$scope"]="${TEST_FILES[$scope]} $file"
            else
                TEST_FILES["general"]="${TEST_FILES[general]} $file"
            fi
            ;;
        chore)
            if [ -n "$scope" ]; then
                CHORE_FILES["$scope"]="${CHORE_FILES[$scope]} $file"
            else
                CHORE_FILES["general"]="${CHORE_FILES[general]} $file"
            fi
            ;;
        refactor)
            if [ -n "$scope" ]; then
                REFACTOR_FILES["$scope"]="${REFACTOR_FILES[$scope]} $file"
            else
                REFACTOR_FILES["general"]="${REFACTOR_FILES[general]} $file"
            fi
            ;;
        perf)
            if [ -n "$scope" ]; then
                PERF_FILES["$scope"]="${PERF_FILES[$scope]} $file"
            else
                PERF_FILES["general"]="${PERF_FILES[general]} $file"
            fi
            ;;
        style)
            if [ -n "$scope" ]; then
                STYLE_FILES["$scope"]="${STYLE_FILES[$scope]} $file"
            else
                STYLE_FILES["general"]="${STYLE_FILES[general]} $file"
            fi
            ;;
        *)
            if [ -n "$scope" ]; then
                OTHER_FILES["$scope"]="${OTHER_FILES[$scope]} $file"
            else
                OTHER_FILES["general"]="${OTHER_FILES[general]} $file"
            fi
            ;;
    esac
    
    # Track file status
    if [ "$is_new" = "true" ]; then
        FILE_STATUS["$file"]="new"
    else
        FILE_STATUS["$file"]="modified"
    fi
done

# Function to output a group
output_group() {
    local group_type="$1"
    local -n files_assoc="$2"
    local group_name="$3"
    
    local groups_output=""
    
    for scope in "${!files_assoc[@]}"; do
        local files_str="${files_assoc[$scope]}"
        [ -z "$files_str" ] && continue
        
        # Clean up the files string
        files_str=$(echo "$files_str" | tr ' ' '\n' | grep -v '^$' | sort | tr '\n' ' ')
        [ -z "$files_str" ] && continue
        
        # Determine the action
        local all_new=true
        for f in $files_str; do
            if [ "${FILE_STATUS[$f]}" != "new" ]; then
                all_new=false
                break
            fi
        done
        
        local action="update"
        if [ "$all_new" = true ]; then
            action="add"
        fi
        
        # Generate description
        local description=""
        if [ -n "$scope" ] && [ "$scope" != "general" ]; then
            description="${action} ${scope}"
        else
            # Use common prefix
            local common_prefix=$(echo "$files_str" | tr ' ' '\n' | head -1 | xargs dirname)
            if [ -n "$common_prefix" ] && [ "$common_prefix" != "." ]; then
                description="${action} ${common_prefix}"
            else
                description="${action} files"
            fi
        fi
        
        # Format output
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            # JSON format
            local files_json=$(echo "$files_str" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s .)
            if [ -n "$scope" ] && [ "$scope" != "general" ]; then
                local message="${group_type}(${scope}): ${description}"
            else
                local message="${group_type}: ${description}"
            fi
            groups_output+="{\"type\": \"${group_type}\", \"scope\": \"${scope}\", \"message\": \"${message}\", \"files\": ${files_json}}, "
        else
            # Text format
            if [ -n "$scope" ] && [ "$scope" != "general" ]; then
                groups_output+="${group_name}: ${group_type}(${scope}): ${description}\n"
            else
                groups_output+="${group_name}: ${group_type}: ${description}\n"
            fi
            groups_output+="  Files: ${files_str}\n\n"
        fi
    done
    
    echo -n "$groups_output"
}

# Output all groups
if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "["
    local first=true
    
    if [ ${#FEAT_FILES[@]} -gt 0 ]; then
        output_group "feat" FEAT_FILES "feat"
        first=false
    fi
    
    if [ ${#FIX_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "fix" FIX_FILES "fix"
        first=false
    fi
    
    if [ ${#DOCS_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "docs" DOCS_FILES "docs"
        first=false
    fi
    
    if [ ${#TEST_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "test" TEST_FILES "test"
        first=false
    fi
    
    if [ ${#CHORE_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "chore" CHORE_FILES "chore"
        first=false
    fi
    
    if [ ${#REFACTOR_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "refactor" REFACTOR_FILES "refactor"
        first=false
    fi
    
    if [ ${#PERF_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "perf" PERF_FILES "perf"
        first=false
    fi
    
    if [ ${#STYLE_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "style" STYLE_FILES "style"
        first=false
    fi
    
    if [ ${#OTHER_FILES[@]} -gt 0 ]; then
        if [ "$first" = false ]; then
            echo -n ","
        fi
        output_group "chore" OTHER_FILES "other"
    fi
    
    echo ""
    echo "]"
else
    echo "Found changes in ${#ALL_FILES_ARRAY[@]} files:"
    echo ""
    
    group_num=1
    
    if [ ${#FEAT_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Feature changes ==="
        output_group "feat" FEAT_FILES "feat"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#FIX_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Bug fixes ==="
        output_group "fix" FIX_FILES "fix"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#DOCS_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Documentation ==="
        output_group "docs" DOCS_FILES "docs"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#TEST_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Tests ==="
        output_group "test" TEST_FILES "test"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#CHORE_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Chores ==="
        output_group "chore" CHORE_FILES "chore"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#REFACTOR_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Refactoring ==="
        output_group "refactor" REFACTOR_FILES "refactor"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#PERF_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Performance ==="
        output_group "perf" PERF_FILES "perf"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#STYLE_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Style changes ==="
        output_group "style" STYLE_FILES "style"
        group_num=$((group_num + 1))
    fi
    
    if [ ${#OTHER_FILES[@]} -gt 0 ]; then
        echo "=== Group $group_num: Other changes ==="
        output_group "chore" OTHER_FILES "other"
    fi
fi

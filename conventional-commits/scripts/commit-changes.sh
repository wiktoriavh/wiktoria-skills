#!/bin/bash

# commit-changes.sh
# Automatically commits changes following Conventional Commits standard
# Part of the conventional-commits skill
#
# Usage: ./commit-changes.sh [--staged|--all] [--dry-run]
#
# Options:
#   --staged    Only commit staged changes (default: all changes)
#   --all       Commit all changes (staged + unstaged + untracked)
#   --dry-run   Show what would be committed without actually committing

set -e

# Determine mode
MODE="all"
DRY_RUN=false

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
        --dry-run)
            DRY_RUN=true
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

# Check for merge conflicts
if git diff --check >/dev/null 2>&1 || git diff --cached --check >/dev/null 2>&1; then
    # No conflicts detected by diff --check, but let's be thorough
    if git status | grep -q "both modified\|both added\|deleted by us\|deleted by them"; then
        echo "Merge conflicts detected. Please resolve them first." >&2
        exit 1
    fi
else
    echo "Merge conflicts detected. Please resolve them first." >&2
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
    echo "No changes found."
    exit 0
fi

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

# Track all files and their info
declare -A FILE_TYPES
declare -A FILE_SCOPES
declare -A FILE_STATUSES

ALL_FILES_ARRAY=($ALL_FILES)

# Process each file to get type, scope, and status
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
    
    FILE_TYPES["$file"]="$file_type"
    FILE_SCOPES["$file"]="$scope"
    FILE_STATUSES["$file"]="$is_new"
done

# Build commit groups
declare -A COMMIT_GROUPS

for file in "${ALL_FILES_ARRAY[@]}"; do
    [ -z "$file" ] && continue
    
    file_type="${FILE_TYPES[$file]}"
    scope="${FILE_SCOPES[$file]}"
    
    # Create group key
    if [ -n "$scope" ] && [ "$scope" != "" ]; then
        group_key="${file_type}(${scope})"
    else
        group_key="${file_type}"
    fi
    
    # Add file to group
    if [ -n "${COMMIT_GROUPS[$group_key]}" ]; then
        COMMIT_GROUPS["$group_key"]="${COMMIT_GROUPS[$group_key]},$file"
    else
        COMMIT_GROUPS["$group_key"]="$file"
    fi
_done

# Function to generate commit message
generate_commit_message() {
    local group_key="$1"
    local files_str="$2"
    
    # Extract type and scope from group_key
    local type="${group_key%%(*}"
    local scope=""
    if [[ "$group_key" =~ \((.*)\) ]]; then
        scope="${BASH_REMATCH[1]}"
    fi
    
    # Determine action
    local all_new=true
    IFS=',' read -ra FILES <<< "$files_str"
    for f in "${FILES[@]}"; do
        if [ "${FILE_STATUSES[$f]}" != "true" ]; then
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
    if [ -n "$scope" ]; then
        description="${action} ${scope}"
    else
        # Use common prefix
        local first_file=$(echo "$files_str" | cut -d',' -f1)
        local common_prefix=$(dirname "$first_file")
        if [ -n "$common_prefix" ] && [ "$common_prefix" != "." ]; then
            description="${action} ${common_prefix}"
        else
            description="${action} files"
        fi
    fi
    
    # Format message
    if [ -n "$scope" ]; then
        echo "${type}(${scope}): ${description}"
    else
        echo "${type}: ${description}"
    fi
}

# Order of commit types for logical ordering
TYPE_ORDER="chore feat fix refactor perf style test docs other"

# Sort groups by type order
declare -a SORTED_GROUPS

for group_key in "${!COMMIT_GROUPS[@]}"; do
    SORTED_GROUPS+=("$group_key")
done

# Custom sort function by type order
IFS=' ' read -ra TYPE_ORDER_ARRAY <<< "$TYPE_ORDER"

sort_groups() {
    local a="$1"
    local b="$2"
    
    local a_type="${a%%(*}"
    local b_type="${b%%(*}"
    
    # Find index in TYPE_ORDER_ARRAY
    local a_index=-1
    local b_index=-1
    for i in "${!TYPE_ORDER_ARRAY[@]}"; do
        if [ "${TYPE_ORDER_ARRAY[$i]}" = "$a_type" ]; then
            a_index=$i
        fi
        if [ "${TYPE_ORDER_ARRAY[$i]}" = "$b_type" ]; then
            b_index=$i
        fi
    done
    
    # If types not found, put them at the end
    if [ $a_index -eq -1 ]; then a_index=100; fi
    if [ $b_index -eq -1 ]; then b_index=100; fi
    
    # Compare by index
    if [ $a_index -lt $b_index ]; then
        return 0
    elif [ $a_index -gt $b_index ]; then
        return 1
    else
        # Same type, sort alphabetically
        if [[ "$a" < "$b" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Simple bubble sort (good enough for small number of groups)
n=${#SORTED_GROUPS[@]}
for i in $(seq 0 $((n-1))); do
    for j in $(seq 0 $((n-i-1))); do
        if ! sort_groups "${SORTED_GROUPS[$j]}" "${SORTED_GROUPS[$((j+1))]}"; then
            # Swap
            temp="${SORTED_GROUPS[$j]}"
            SORTED_GROUPS[$j]="${SORTED_GROUPS[$((j+1))]}"
            SORTED_GROUPS[$((j+1))]="$temp"
        fi
    done
done

# Execute commits
echo "Found changes in ${#ALL_FILES_ARRAY[@]} files"
echo ""

COMMITS_CREATED=0
COMMIT_SUMMARY=""

for group_key in "${SORTED_GROUPS[@]}"; do
    files_str="${COMMIT_GROUPS[$group_key]}"
    
    # Skip empty groups
    [ -z "$files_str" ] && continue
    
    # Generate commit message
    commit_message=$(generate_commit_message "$group_key" "$files_str")
    
    # Convert comma-separated files to space-separated
    files_space=$(echo "$files_str" | tr ',' ' ')
    
    # Display what will be committed
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would commit: $commit_message"
        echo "[DRY RUN] Files: $files_space"
        echo ""
        continue
    fi
    
    # Stage files
    if [ -n "$files_space" ]; then
        if $DRY_RUN; then
            echo "Would stage: $files_space"
        else
            # Use git add with --all or specific files
            # For untracked files, we need to use git add
            for file in $files_space; do
                git add "$file" 2>/dev/null || {
                    echo "Error: Failed to stage file: $file" >&2
                    exit 1
                }
            done
        fi
    fi
    
    # Commit
    if [ "$DRY_RUN" = false ]; then
        # Check if there are any staged files
        STAGED_COUNT=$(git diff --cached --name-only | wc -l)
        if [ "$STAGED_COUNT" -eq 0 ]; then
            echo "No files staged for commit: $commit_message"
            continue
        fi
        
        # Create the commit
        if git commit -m "$commit_message" --no-verify 2>/dev/null; then
            COMMITS_CREATED=$((COMMITS_CREATED + 1))
            COMMIT_SUMMARY+="✓ $commit_message\n"
            
            # Get the commit hash
            COMMIT_HASH=$(git rev-parse HEAD)
            SHORT_HASH=${COMMIT_HASH:0:7}
            COMMIT_SUMMARY+="  $SHORT_HASH\n"
            
            # Show files
            for file in $files_space; do
                COMMIT_SUMMARY+="    - $file\n"
            done
            COMMIT_SUMMARY+="\n"
        else
            echo "Error: Failed to create commit: $commit_message" >&2
            echo "Files that were staged:"
            git diff --cached --name-only | while read f; do
                echo "  $f"
            done
            echo ""
            echo "You may need to manually unstage files and retry."
            exit 1
        fi
    fi
done

# Summary
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "Dry run complete. No changes were made."
else
    echo ""
    echo "========================================="
    echo "Commits created successfully!"
    echo "========================================="
    echo ""
    echo -e "$COMMIT_SUMMARY"
    echo "Total commits: $COMMITS_CREATED"
    
    if [ $COMMITS_CREATED -gt 0 ]; then
        echo ""
        echo "Git log:"
        git log --oneline -n $COMMITS_CREATED
    fi
fi

exit 0

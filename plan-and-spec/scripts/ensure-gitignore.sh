#!/bin/bash

# ensure-gitignore.sh
# Ensures that AI scratchpad files are properly gitignored.
# Called by the plan-and-spec skill on invocation.

set -e

SCRATCHPAD_PATTERN="*.ai-scratchpad.md"
CLAUDE_PATTERN="*.claude.md"

# Function to add pattern to a file if not present
ensure_pattern() {
    local file_path="$1"
    local pattern="$2"
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        # Create directory if needed
        mkdir -p "$(dirname "$file_path")"
        echo "$pattern" > "$file_path"
        echo "Created $file_path and added pattern: $pattern"
        return 0
    fi
    
    # Check if pattern exists
    if grep -qFx "$pattern" "$file_path" 2>/dev/null; then
        echo "Pattern already exists in $file_path: $pattern"
        return 0
    fi
    
    # Check if pattern exists as a comment
    if grep -q "$pattern" "$file_path" 2>/dev/null; then
        echo "Pattern mentioned in $file_path: $pattern"
        return 0
    fi
    
    # Add pattern to file
    echo "$pattern" >> "$file_path"
    echo "Added pattern to $file_path: $pattern"
    return 0
}

echo "Ensuring gitignore for scratchpad files in: $(pwd)"

# 1. Check .gitignore
GITIGNORE_PATH=".gitignore"
ensure_pattern "$GITIGNORE_PATH" "$SCRATCHPAD_PATTERN"
ensure_pattern "$GITIGNORE_PATH" "$CLAUDE_PATTERN"

# 2. Check .git/info/exclude
EXCLUDE_PATH=".git/info/exclude"
ensure_pattern "$EXCLUDE_PATH" "$SCRATCHPAD_PATTERN"
ensure_pattern "$EXCLUDE_PATH" "$CLAUDE_PATTERN"

echo ""
echo "Gitignore setup complete."
echo "Run 'git rm --cached *.ai-scratchpad.md' if files were previously tracked."

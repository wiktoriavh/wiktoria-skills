#!/bin/bash

# Global Skills Setup Script
# This script symlinks all skills from this repository to both
# Mistral Vibe and Claude Code's skills directories for global access.
#
# Usage:
#   ./setup-global.sh        - Install/update all skills
#   ./setup-global.sh --clean - Remove all symlinks first

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISTRAL_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/code/skills"

echo "Skills Repository: $REPO_DIR"
echo ""

# Create target directories if they don't exist
mkdir -p "$MISTRAL_SKILLS"
mkdir -p "$CLAUDE_SKILLS"

# Clean up old symlinks if requested
if [ "$1" = "--clean" ]; then
    echo "Cleaning up old symlinks..."
    
    # Remove symlinks in Mistral that point to our repo
    find "$MISTRAL_SKILLS" -maxdepth 1 -type l -exec sh -c 'for l; do [ "$(readlink "$l")" = "'"$REPO_DIR"'/*" ] && rm "$l"; done' _ {} +
    
    # Remove symlinks in Claude that point to our repo  
    find "$CLAUDE_SKILLS" -maxdepth 1 -type l -exec sh -c 'for l; do [ "$(readlink "$l")" = "'"$REPO_DIR"'/*" ] && rm "$l"; done' _ {} +
    
    echo "Cleaned up old symlinks."
    echo ""
fi

# Find all skill directories in the repo (directories containing SKILL.md)
SKILLS=()
while IFS= read -r -d '' skill_dir; do
    skill_name=$(basename "$skill_dir")
    SKILLS+=("$skill_name")
done < <(find "$REPO_DIR" -maxdepth 2 -name "SKILL.md" -printf '%h\0' 2>/dev/null)

if [ ${#SKILLS[@]} -eq 0 ]; then
    echo "No skills found in repository."
    exit 1
fi

# Install symlinks for each skill
for skill in "${SKILLS[@]}"; do
    src="$REPO_DIR/$skill"
    
    # Mistral Vibe
    mistral_dest="$MISTRAL_SKILLS/$skill"
    if [ -L "$mistral_dest" ]; then
        if [ "$(readlink "$mistral_dest")" = "$src" ]; then
            echo "✓ Mistral: $skill (already linked)"
        else
            rm "$mistral_dest"
            ln -sfn "$src" "$mistral_dest"
            echo "✓ Mistral: $skill (updated)"
        fi
    elif [ -e "$mistral_dest" ]; then
        echo "⚠ Mistral: $skill (already exists as file/dir, skipping)"
    else
        ln -sfn "$src" "$mistral_dest"
        echo "✓ Mistral: $skill (installed)"
    fi
    
    # Claude Code
    claude_dest="$CLAUDE_SKILLS/$skill"
    if [ -L "$claude_dest" ]; then
        if [ "$(readlink "$claude_dest")" = "$src" ]; then
            echo "  ✓ Claude: $skill (already linked)"
        else
            rm "$claude_dest"
            ln -sfn "$src" "$claude_dest"
            echo "  ✓ Claude: $skill (updated)"
        fi
    elif [ -e "$claude_dest" ]; then
        echo "  ⚠ Claude: $skill (already exists as file/dir, skipping)"
    else
        ln -sfn "$src" "$claude_dest"
        echo "  ✓ Claude: $skill (installed)"
    fi
done

echo ""
echo "Global skills setup complete!"
echo ""
echo "Mistral skills: $MISTRAL_SKILLS"
echo "Claude skills:  $CLAUDE_SKILLS"
echo ""
echo "To update after adding new skills to the repo, just run: ./setup-global.sh"

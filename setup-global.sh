#!/bin/bash

# Global Skills Setup Script
# This script symlinks all skills from this repository to specified
# agent platforms' skills directories for global access.
#
# Usage:
#   ./setup-global.sh                    - Interactive prompt
#   ./setup-global.sh --mistral          - Install to Mistral Vibe only
#   ./setup-global.sh --claude           - Install to Claude Code only
#   ./setup-global.sh --both             - Install to both (default)
#   ./setup-global.sh --clean [targets]  - Remove old symlinks first
#
# Targets can be combined: ./setup-global.sh --mistral --claude

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISTRAL_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/code/skills"

# ANSI color codes
DIM='\e[2m'
RESET='\e[0m'
BOLD='\e[1m'
GREEN='\e[32m'
CYAN='\e[36m'
SELECTED_BG='\e[7;30m'
SELECTED_FG='\e[1;7m'

# Default to both platforms
INSTALL_MISTRAL=true
INSTALL_CLAUDE=true

# Array of menu options
MENU_OPTIONS=(
    "Agents directory ($HOME/.agents/skills) ${DIM}- Used by: Mistral Vibe${RESET}"
    "Claude directory ($HOME/.claude/code/skills) ${DIM}- Used by: Claude Code${RESET}"
    "Both platforms (default)"
    "Custom path"
)

echo "Skills Repository: $REPO_DIR"
echo ""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mistral)
            INSTALL_MISTRAL=true
            INSTALL_CLAUDE=false
            shift
            ;;
        --claude)
            INSTALL_MISTRAL=false
            INSTALL_CLAUDE=true
            shift
            ;;
        --both)
            INSTALL_MISTRAL=true
            INSTALL_CLAUDE=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--mistral] [--claude] [--both] [--clean]"
            exit 1
            ;;
    esac
done

# Interactive arrow-key menu function
show_menu() {
    local selected=0
    local options=("${MENU_OPTIONS[@]}")
    local title="Where would you like to install the skills?"
    
    # Save current cursor position
    echo -ne "\e[s"
    
    while true; do
        # Clear menu area (move up and overwrite)
        echo -ne "\e[2J\e[H"  # Clear screen and move to home
        echo "$title"
        echo ""
        
        # Draw menu options
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${SELECTED_FG}> ${options[i]} ${RESET}<${RESET}"
            else
                echo -e "    ${options[i]}"
            fi
        done
        
        echo ""
        echo -e "${DIM}Use arrow keys to navigate, Enter to select, ESC to default${RESET}"
        
        # Read a single character (no newline)
        read -rsn1 key
        
        # Handle escape sequences (arrow keys start with ESC)
        if [[ "$key" == $'\e' ]]; then
            read -rsn2 -t 0.1 key2
            case "$key2" in
                "[A") # Up arrow
                    if [ $selected -gt 0 ]; then
                        selected=$((selected - 1))
                    fi
                    ;;
                "[B") # Down arrow
                    if [ $selected -lt $(( ${#options[@]} - 1 )) ]; then
                        selected=$((selected + 1))
                    fi
                    ;;
                "[C") # Right arrow - same as Enter
                    break
                    ;;
            esac
        elif [[ "$key" == "" ]]; then
            # Timeout or error, continue
            continue
        else
            case "$key" in
                $'\n') # Enter
                    break
                    ;;
                $'\r') # Enter (carriage return)
                    break
                    ;;
                $'\x1b') # ESC key
                    selected=2  # Default to "Both platforms"
                    break
                    ;;
                "q"|"Q")
                    echo ""
                    exit 0
                    ;;
                [1-4])
                    selected=$((key - 1))
                    break
                    ;;
            esac
        fi
    done
    
    # Move cursor down to clear the menu
    echo -ne "\e[999B"
    return $selected
}

# If no target specified and not in a TTY (non-interactive), default to both
if [[ -z "$1" && ! -t 0 && ! -t 1 ]]; then
    # Non-interactive mode with no args - use both
    INSTALL_MISTRAL=true
    INSTALL_CLAUDE=true
elif [[ -z "${1:-}" ]]; then
    # Interactive mode with arrow keys
    show_menu
    choice=$?
    
    case "$choice" in
        0)
            INSTALL_MISTRAL=true
            INSTALL_CLAUDE=false
            ;;
        1)
            INSTALL_MISTRAL=false
            INSTALL_CLAUDE=true
            ;;
        2)
            INSTALL_MISTRAL=true
            INSTALL_CLAUDE=true
            ;;
        3)
            read -p "Enter custom path for Mistral skills (leave empty to skip): " custom_mistral
            if [[ -n "$custom_mistral" ]]; then
                MISTRAL_SKILLS="$custom_mistral"
                INSTALL_MISTRAL=true
            else
                INSTALL_MISTRAL=false
            fi
            read -p "Enter custom path for Claude skills (leave empty to skip): " custom_claude
            if [[ -n "$custom_claude" ]]; then
                CLAUDE_SKILLS="$custom_claude"
                INSTALL_CLAUDE=true
            else
                INSTALL_CLAUDE=false
            fi
            ;;
        *)
            echo "Invalid option, defaulting to both platforms."
            INSTALL_MISTRAL=true
            INSTALL_CLAUDE=true
            ;;
    esac
    echo ""
fi

# Create target directories if they don't exist
if [[ "$INSTALL_MISTRAL" = true ]]; then
    mkdir -p "$MISTRAL_SKILLS"
fi
if [[ "$INSTALL_CLAUDE" = true ]]; then
    mkdir -p "$CLAUDE_SKILLS"
fi

# Clean up old symlinks if requested
if [[ "$CLEAN" = true ]]; then
    echo "Cleaning up old symlinks..."
    
    if [[ "$INSTALL_MISTRAL" = true ]]; then
        find "$MISTRAL_SKILLS" -maxdepth 1 -type l -exec sh -c 'for l; do [ "$(readlink "$l")" = "'"$REPO_DIR"'/*" ] && rm "$l"; done' _ {} +
    fi
    
    if [[ "$INSTALL_CLAUDE" = true ]]; then
        find "$CLAUDE_SKILLS" -maxdepth 1 -type l -exec sh -c 'for l; do [ "$(readlink "$l")" = "'"$REPO_DIR"'/*" ] && rm "$l"; done' _ {} +
    fi
    
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

echo "Found skills: ${SKILLS[*]}"
echo ""

# Install symlinks for each skill
for skill in "${SKILLS[@]}"; do
    src="$REPO_DIR/$skill"
    
    # Mistral Vibe
    if [[ "$INSTALL_MISTRAL" = true ]]; then
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
    fi
    
    # Claude Code
    if [[ "$INSTALL_CLAUDE" = true ]]; then
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
    fi
done

echo ""

# Show summary
if [[ "$INSTALL_MISTRAL" = true ]]; then
    echo "Mistral skills installed to: $MISTRAL_SKILLS"
fi
if [[ "$INSTALL_CLAUDE" = true ]]; then
    echo "Claude skills installed to:  $CLAUDE_SKILLS"
fi

if [[ "$INSTALL_MISTRAL" = false && "$INSTALL_CLAUDE" = false ]]; then
    echo "No platforms selected for installation."
fi

echo ""
echo "To update after adding new skills to the repo, just run: ./setup-global.sh"

---
name: hello-world
description: A simple hello world skill that demonstrates basic skill functionality and serves as a test/verification skill for both Claude and Mistral agent systems.
authors: [wiktoria]
version: 1.0.0
---

# Hello World Skill

This is a minimal skill that responds to hello world requests. It serves as:
- A test skill to verify skill loading works in both Claude and Mistral
- A template for creating new skills
- A simple demonstration of skill functionality

## Usage

When the user asks the agent to "say hello", "hello world", or similar greeting requests, the skill should respond with a friendly hello message.

## Compatibility

This skill is designed to be compatible with both:
- **Claude Code** agent system
- **Mistral Vibe** agent system

Both systems support the same SKILL.md format with YAML frontmatter containing metadata.

## Examples

### User Request
> "hello"
> "say hello world"
> "can you say hello?"
> "test hello world"

### Expected Response
> "Hello, World!"
> "Hello! This is the hello-world skill responding."

## Implementation Notes

This is a passive skill that provides contextual instructions for the agent. When loaded, it guides the agent to recognize hello world patterns and respond appropriately.

## Testing

To test this skill:
1. Install/load the skill in your agent system
2. Ask the agent to "say hello world" or similar
3. Verify it responds with a hello message

---
skill_type: instruction

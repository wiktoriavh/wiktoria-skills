# plan-and-spec Skill

A structured document workflow skill that helps you create plans, specs, and other documents with **logical progression** and **no forward references**.

## Features

- **Dual-document system**: Main document (human-controlled) + AI scratchpad (AI-controlled, gitignored)
- **Confidence tracking**: YAML header in scratchpad tracks business, technical, and overall confidence
- **Logical ordering**: Enforces business-before-technical and no forward references
- **Session persistence**: Scratchpad maintains context across sessions
- **Interactive**: Uses `ask_user_question` for all clarifications

## Quick Start

### Create a new document

```
User: /plan-and-spec user-authentication
AI: [Starts workflow, creates docs/user-authentication.md and docs/user-authentication.ai-scratchpad.md]
```

### Resume existing work

```
User: /plan-and-spec user-authentication
AI: [Reads existing files, resumes from where you left off]
```

## Directory Structure

```
repo/
├── .gitignore                    # Contains: *.ai-scratchpad.md
├── docs/
│   ├── user-authentication.md     # Main document (human-controlled)
│   └── user-authentication.ai-scratchpad.md  # AI scratchpad (gitignored)
└── plan-and-spec/
    ├── SKILL.md                  # Skill definition
    ├── scratchpad-template.md    # Template for new scratchpads
    └── scripts/
        └── ensure-gitignore.sh   # Gitignore setup script
```

## Document Structure

All documents follow this **mandatory** order:

1. **Business Definition** - Purpose, goals, audience, success criteria
2. **Business Concepts** - Domain terms and definitions
3. **Technical Requirements** - Constraints, architecture, implementation
4. **Features and Capabilities** - Ordered by dependencies

**Rule:** You cannot reference any concept before it's been defined earlier in the document.

## Scratchpad YAML Header

```yaml
---
scratchpad-for: user-authentication.md
document-type: spec
confidence:
  overall: 65
  business: 80
  technical: 50
  last-updated: 2024-01-15T10:00:00Z
  notes: |
    Business definition complete. Technical requirements in progress.
---
```

## Gitignore Script

The skill includes a script to automatically ensure scratchpad files are gitignored:

- **`scripts/ensure-gitignore.sh`** - Bash script

The AI calls this script at the beginning of every invocation:
```bash
./plan-and-spec/scripts/ensure-gitignore.sh
```

This script:
- Creates `.gitignore` if it doesn't exist
- Adds `*.ai-scratchpad.md` to `.gitignore`
- Adds `*.ai-scratchpad.md` to `.git/info/exclude`
- Also adds `*.claude.md` for compatibility

## Confidence Levels

- **0-30%**: Just started, many unknowns
- **30-60%**: Basic structure, details pending
- **60-80%**: Most content defined, refinements needed
- **80-100%**: Ready for final review

## Workflow Phases

### Phase 1: Business Definition
- Define purpose, goals, audience
- Establish success criteria
- **Blocked by:** Nothing (can start fresh)
- **Unblocks:** Phase 2

### Phase 2: Business Concepts
- Define all domain terms
- Establish business language
- **Blocked by:** Phase 1 incomplete (confidence < 80%)
- **Unblocks:** Phase 3

### Phase 3: Technical Requirements
- Define technical constraints
- Make architecture decisions
- **Blocked by:** Phase 2 incomplete (confidence < 80%)
- **Unblocks:** Phase 4

### Phase 4: Features and Capabilities
- Define features in dependency order
- Each feature references only previously defined concepts
- **Blocked by:** Phase 3 incomplete (confidence < 60%)

## Gitignore Setup

The skill automatically ensures `*.ai-scratchpad.md` is in `.gitignore`. It also checks `.git/info/exclude` for local exclusion.

## Usage Patterns

### Pattern 1: Start fresh
```
User: Create a spec for the payment system
AI: What should we name this document? (default: docs/payment-system.md)
User: payment-system is fine
AI: [Creates files, starts Business Definition phase]
```

### Pattern 2: Resume work
```
User: Continue the payment system spec
AI: [Reads scratchpad] Last session we completed Business Definition (85%) and started Business Concepts. Open questions: [list]
User: Let's tackle the open questions
AI: [Continues from where left off]
```

### Pattern 3: Pause and resume later
```
User: I need to pause for now
AI: [Saves draft to main doc, updates scratchpad] Saved progress. Business Definition complete (90%), Business Concepts at 60%. Open questions: [list]. Ready to pause.

[Later...]

User: Resume payment system spec
AI: [Reads scratchpad] Ready to continue? Last we had [X] pending.
```

## Commands

- `/plan-and-spec <name>` - Create or resume document
- `/plan-and-spec` - List existing documents with scratchpads

## Integration with Other Skills

This skill works well with:
- `askme` - For clarifying individual statements within the document
- `brainstorm` - For generating ideas before formalizing in the spec
- `grilling` - For stress-testing technical decisions
- `iterative-doc` - Similar workflow, but with different naming conventions

## Configuration

You can customize:
- Default document folder (default: `docs/`)
- Scratchpad naming pattern (default: `<filename>.ai-scratchpad.md`)

## Best Practices

1. **Always use ask_user_question** when unclear about order, scope, or details
2. **Update confidence levels** after every significant change
3. **Verify no forward references** before finalizing any section
4. **Commit scratchpad frequently** (but it should be gitignored, so use `git add -f` if needed for backup)
5. **Main document is human-controlled** - only write drafts, never finalize without user approval

## Troubleshooting

**Problem:** Scratchpad file is being committed to git

**Solution:** Ensure `*.ai-scratchpad.md` is in `.gitignore` and `.git/info/exclude`

**Problem:** Document has forward references

**Solution:** Reorder sections or add missing introductory sections. Use `ask_user_question` to confirm correct order with user.

**Problem:** Confidence levels seem inaccurate

**Solution:** Review scratchpad notes and adjust confidence based on actual progress. Be conservative - it's better to underestimate than overestimate.

## File Templates

See `scratchpad-template.md` for the standard scratchpad template.

## License

This skill is provided as-is. Feel free to modify and adapt for your needs.

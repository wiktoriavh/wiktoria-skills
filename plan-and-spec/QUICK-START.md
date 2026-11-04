# Quick Start: plan-and-spec Skill

## TL;DR

```
You: /plan-and-spec my-project-plan
AI: Creates docs/my-project-plan.md + docs/my-project-plan.ai-scratchpad.md
     [Starts asking questions to define business objectives]
```

## The Two Files

| File | Controlled By | Purpose | Git Status |
|------|---------------|---------|------------|
| `docs/my-project-plan.md` | Human | Finalized content only | Tracked |
| `docs/my-project-plan.ai-scratchpad.md` | AI | Working memory, confidence, open questions | **Ignored** |

## The Rule

❌ **DON'T DO THIS:**
```markdown
## Features

### Advanced Feature
Builds on Basic Feature.

### Basic Feature  
The foundation.
```

✅ **DO THIS:**
```markdown
## Features

### Basic Feature
The foundation.

### Advanced Feature
Builds on Basic Feature.
```

**Every concept must be introduced BEFORE it's referenced.**

## Document Order

1. **Business Definition** (Who, What, Why, Success)
2. **Business Concepts** (Domain terms, language)
3. **Technical Requirements** (How, Constraints)
4. **Features** (In dependency order)

## Confidence Tracking

```yaml
---
confidence:
  overall: 75
  business: 90
  technical: 60
---
```

- 0-30%: Just starting
- 30-60%: Basic structure
- 60-80%: Mostly defined
- 80-100%: Ready for review

## Commands

| Command | Action |
|---------|--------|
| `/plan-and-spec <name>` | Create or resume document |
| Continue working | AI reads scratchpad, resumes where left off |
| "Pause for now" | AI saves state, updates confidence |

## Example Session

```
User: /plan-and-spec user-management

AI: Let's start with the business definition. What's the primary purpose 
    of the user management system?
    
    Options:
    - Authentication and authorization
    - User profile management
    - User analytics and reporting
    - All of the above

User: All of the above

AI: Who are the primary stakeholders for this system?
    
    Options:
    - End users
    - Administrators
    - Developers
    - All of the above

User: All of the above

AI: [Writes to main doc, updates scratchpad confidence]
    Business Definition: 30% complete
    
    Next: Should we define "user" as a concept, or move to "authentication"?

User: Define "user" first

AI: [Adds Business Concepts section]
    
    What is a "user" in this context?
    Options:
    - Any person who interacts with the system
    - Only registered accounts
    - Both registered and anonymous users

User: Only registered accounts

AI: [Continues...]
```

## What the AI Does

✅ **AI Does:**
- Creates and maintains scratchpad
- Tracks confidence levels
- Enforces document order
- Asks clarifying questions
- Drafts content to main doc
- Verifies no forward references

❌ **AI Does NOT:**
- Commit main document
- Make autonomous decisions
- Allow forward references
- Edit without asking

## What the Human Does

✅ **Human Does:**
- Controls main document content
- Answers AI questions
- Reviews and approves drafts
- Decides when to pause/resume
- Commits main document

❌ **Human Does NOT:**
- Edit scratchpad directly
- Need to remember context (scratchpad does this)

## Git Setup

The skill automatically adds this to `.gitignore`:
```
*.ai-scratchpad.md
```

And to `.git/info/exclude`:
```
*.ai-scratchpad.md
```

So scratchpad files are **never committed** to git.

## Need Help?

Read the full documentation in:
- `SKILL.md` - Complete skill definition
- `README.md` - Detailed usage guide
- `scratchpad-template.md` - Scratchpad file template

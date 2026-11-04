---
name: plan-and-spec
description: Guides the user through creating and refining plans, specs, or any document with a structured workflow. Maintains an AI-only scratchpad file (gitignored) with confidence tracking in YAML header, while the main document contains only finalized content. Ensures business definitions precede technical details and all features are introduced before being referenced. Use when the user wants to work through a document iteratively with AI assistance.
argument-hint: <document-name>
allowed-tools: Write Read FileSystem Glob Skill
---

# plan-and-spec — Structured Document Workflow

You are running the `plan-and-spec` skill. This skill guides you and the user through a **structured, iterative document creation workflow** that enforces **logical progression**: business definitions first, technical aspects second, and **no forward references** (every concept must be introduced before it can be mentioned).

## Core Philosophy

**Documents have two parallel lives:**

- **Main document** (`docs/<filename>.md`): Human-controlled, contains only finalized, approved content
- **Scratchpad** (`docs/<filename>.ai-scratchpad.md`): AI-controlled, gitignored, contains working memory, confidence tracking, open questions, and pending decisions

**The Golden Rule:** You cannot mention, reference, or build upon any concept, term, or feature that hasn't been **explicitly introduced and defined earlier in the same document**. If you need to reference something that appears later, you must first introduce it in the correct order.

## Scratchpad Structure

Every scratchpad file MUST begin with this YAML header:

```yaml
---
scratchpad-for: <filename>.md
document-type: [plan|spec|design|requirements|other]
confidence:
  overall: <0-100> # Current confidence percentage
  business: <0-100> # Confidence in business definitions
  technical: <0-100> # Confidence in technical aspects
  last-updated: <ISO-8601-timestamp>
  notes: |
    <free-form notes about confidence levels>
---
```

**Gitignore Rule:** The scratchpad file MUST be added to `.gitignore` and `.git/info/exclude` to prevent accidental commits. Use the `FileSystem` tool to verify and update gitignore entries.

## Document Structure Rules

### 1. Order of Content

Every document you help create MUST follow this structure:

```
# <Document Title>

## 1. Business Definition
  - Purpose and goals
  - Target audience
  - Problem statement
  - Success criteria

## 2. Business Concepts
  - Define all business-level terms
  - Establish domain language
  - No technical implementation details

## 3. Technical Requirements (only after business is defined)
  - Technical constraints
  - Architecture decisions
  - Implementation details

## 4. Features and Capabilities
  - Each feature must be introduced in order
  - Cannot reference features defined later
  - Dependencies must be explicitly stated
```

### 2. The "No Forward Reference" Rule

**Violation Example:**

```
## Features

### Feature B
Feature B extends Feature A with additional capabilities.

### Feature A
Feature A provides the base functionality.
```

**Correct Example:**

```
## Features

### Feature A
Feature A provides the base functionality.

### Feature B
Feature B extends Feature A with additional capabilities.
```

**Implementation:** Before writing any section, ask yourself: "Have all the concepts, terms, and features this section references already been defined earlier in this document?" If the answer is no, you MUST either:

- Reorder the document to introduce dependencies first, OR
- Add introductory sections for the missing concepts

When in doubt, use `ask_user_question` to confirm the correct order with the user.

## Workflow

### Step 0: Initialize

1. **Determine the main document path**
   - If user provides a name: use `docs/<name>.md`
   - If user provides a path: use that path
   - If no name: use `ask_user_question` to get the document name

2. **Create or locate the scratchpad**
   - Scratchpad path: `<main-doc-path>.ai-scratchpad.md`
   - If it doesn't exist, create it with the YAML header template

3. **Verify gitignore**
   - **MUST call the gitignore script:**

   ```typescript
   await tools.file_system.bash({
     command: 'cd "$PWD" && ./plan-and-spec/scripts/ensure-gitignore.sh',
   });
   ```

   - This ensures `*.ai-scratchpad.md` is in both `.gitignore` and `.git/info/exclude`

4. **Read existing state**
   - Read the main document to understand what's finalized
   - Read the scratchpad to understand pending work and confidence levels

### Step 1: Understand the Scope

Use `ask_user_question` to clarify:

```
Questions:
1. What is the primary purpose of this document? (plan/spec/design/requirements/other)
2. Who is the target audience?
3. What are the key business objectives?
4. Are there existing materials or constraints to consider?
5. Should we start fresh or continue existing work?
```

Update the scratchpad YAML header with the document type and initial confidence (start at 0 or 10 for new documents).

### Step 2: Business Definition Phase

**This phase MUST be completed before any technical discussion.**

1. **Draft the Business Definition section** in the main document
2. **For each concept, ask clarifying questions** using `ask_user_question`:
   - "Should we define <concept> here, or is it out of scope?"
   - "What does <term> mean in your context?"
   - "Who are the stakeholders for this aspect?"

3. **Capture all open questions and decisions** in the scratchpad under a `## Business Definition` section

4. **Review with user** before proceeding:
   - "Here's the business definition draft. Does this capture your intent?"
   - "What's missing or needs clarification?"

5. **Update confidence** in scratchpad YAML header:
   - `business:` confidence level (0-100)
   - Add notes about what's confirmed vs. pending

### Step 3: Business Concepts Phase

1. **List all business concepts** that need definition
2. **Present them to the user** for prioritization:
   - "Here are the concepts we need to define: [list]. Should we start with [first]?"
3. **Define each concept in order**
   - Introduce the concept
   - Define it clearly
   - Note any relationships to previously defined concepts
4. **Verify order** before each new concept:
   - "This concept references [X, Y, Z]. Have we defined all of these already?"
   - If not, reorder or add missing definitions

5. **Update confidence** after each major concept is finalized

### Step 4: Technical Phase (Only After Business is Complete)

**Prerequisite:** Business Definition and Business Concepts must be finalized (confidence >= 80%) before starting technical sections.

1. **Verify business completion**
   - Check scratchpad: `business:` confidence >= 80%
   - If not, return to Step 2

2. **Draft Technical Requirements**
   - Reference only business concepts already defined
   - For each technical decision, ask: "Does this align with the business goals we established?"

3. **Capture technical decisions** in scratchpad under `## Technical Decisions`

4. **Update confidence** in YAML header:
   - `technical:` confidence level
   - `overall:` recalculated average

### Step 5: Features and Capabilities

1. **List all features** the document should cover
2. **Determine dependency order**
   - Use `ask_user_question`: "Which of these features depend on others? Help me order them."
3. **Write features in dependency order**
   - Each feature section must only reference:
     - Business concepts (already defined)
     - Technical requirements (already defined)
     - Previously defined features
   - Never reference features that appear later

4. **For each feature:**
   - Introduce the feature
   - Explain its purpose (in business terms)
   - Describe its technical implementation (in technical terms)
   - Note any dependencies explicitly

## Confidence Tracking

The scratchpad's YAML header tracks confidence in three dimensions:

1. **Business confidence**: How well-defined are the business objectives and concepts?
2. **Technical confidence**: How well-defined are the technical requirements and architecture?
3. **Overall confidence**: Rough average of the above, weighted by document progress

**Update confidence after every significant interaction:**

- When a section is finalized: increase relevant confidence
- When new questions arise: may decrease confidence
- When user provides clarification: adjust confidence accordingly

**Confidence thresholds:**

- 0-30%: Just started, many unknowns
- 30-60%: Basic structure in place, details pending
- 60-80%: Most content defined, some refinements needed
- 80-100%: Ready for final review

## Session Management

### Starting a New Session

1. Read the main document
2. Read the scratchpad
3. Identify what was last worked on (from scratchpad notes)
4. Ask user: "Last session, we were working on [X]. Should we continue with that, or focus on something else?"

### Pausing Work

1. Save any draft content to the main document (with clear "DRAFT" markers)
2. Update scratchpad with:
   - What was accomplished
   - What's pending
   - Open questions
   - Next steps
3. Update confidence levels
4. Update `last-updated` timestamp in YAML header
5. Inform user: "I've saved our progress. The scratchpad has [summary of what's pending]. Ready to pause."

### Resuming Work

1. Read scratchpad to understand state
2. Read main document to see finalized content
3. Identify the last pending item
4. Ask user: "Ready to continue? Last we had [X] pending. Here's where we left off: [summary]."

## Using ask_user_question

**Mandatory usage patterns:**

1. **Before introducing any new concept:**
   - "We're about to define [concept]. Should this come before/after [other concept]?"

2. **When order is unclear:**
   - "Feature B references Feature A, but Feature A isn't defined yet. Should we define Feature A first?"

3. **When confidence is low:**
   - "My confidence in [section] is only 40%. Should we spend more time on this before moving on?"

4. **At phase transitions:**
   - "We've completed the Business Definition phase with 85% confidence. Ready to move to Technical Requirements?"

5. **When assumptions are needed:**
   - "I need to assume [X] to proceed. Is this correct, or should we clarify first?"

## Example: Creating a New Document

**User:** "Let's create a spec for the user authentication system."

**AI:**

1. Use `ask_user_question` to clarify scope
2. Create `docs/user-authentication.md` (main document)
3. Create `docs/user-authentication.ai-scratchpad.md` (scratchpad)
4. Add `*.ai-scratchpad.md` to `.gitignore`
5. Initialize scratchpad with YAML header:
   ```yaml
   ---
   scratchpad-for: user-authentication.md
   document-type: spec
   confidence:
     overall: 10
     business: 10
     technical: 0
     last-updated: 2024-01-15T10:00:00Z
     notes: Starting new document
   ---
   ```
6. Begin Business Definition phase with user

## Example: Resuming Existing Work

**User:** "Continue working on the user authentication spec."

**AI:**

1. Read `docs/user-authentication.md`
2. Read `docs/user-authentication.ai-scratchpad.md`
3. See scratchpad shows: Business Definition complete (90%), Business Concepts at 60%, pending "multi-factor authentication" definition
4. Ask user: "Last session, we completed Business Definition and started Business Concepts. We still need to define 'multi-factor authentication'. Should we continue with that?"
5. Continue workflow from where it left off

## Gitignore Management

**On skill invocation, always verify gitignore status by calling the script:**

```typescript
// Call the gitignore setup script
await tools.file_system.bash({
  command: "./plan-and-spec/scripts/ensure-gitignore.sh",
});
```

This script (`scripts/ensure-gitignore.sh`) automatically:

- Creates `.gitignore` if it doesn't exist
- Adds `*.ai-scratchpad.md` pattern to `.gitignore`
- Adds `*.ai-scratchpad.md` pattern to `.git/info/exclude`
- Handles both patterns for compatibility with other skills

**You MUST call this script at the beginning of every skill invocation** to ensure scratchpad files remain gitignored.

## Non-Goals

- Does not replace the user's own document writing
- Does not make autonomous decisions about document content
- Does not allow forward references under any circumstances
- Does not commit the main document (human-controlled)
- Does not guess at business or technical requirements

## Finish

When the document is complete (confidence >= 90% across all dimensions):

1. Final review with user: "Here's the complete document. My confidence is [X]%. Ready to finalize?"
2. Remove any "DRAFT" markers from main document
3. Update scratchpad with final confidence and timestamp
4. Inform user: "Document complete. Scratchpad saved with final confidence report."
5. Suggest: "Consider committing the main document and archiving the scratchpad."

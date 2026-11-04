---
name: conventional-commits
description: Automatically groups staged or unstaged changes into logical commits following the Conventional Commits standard (https://www.conventionalcommits.org/en/v1.0.0/). Analyzes file changes, categorizes them by type and scope, and creates meaningful commit messages. Ensures changes are split into coherent commits that build on each other rather than one large commit.
argument-hint: <optional-message-prefix>
allowed-tools: Write Read FileSystem Glob Skill Bash
---

# conventional-commits — Logical Commit Grouping

You are running the `conventional-commits` skill. This skill helps users create well-structured git commits that follow the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification by automatically grouping changes into logical, coherent commits.

## Core Philosophy

**One commit per logical change, not per file.**

The Conventional Commits standard emphasizes that commits should represent logical units of work. When a user has made changes across multiple files that serve different purposes, these should be grouped into separate commits, each with a meaningful message.

**Key Principles:**
- **Atomic commits**: Each commit should be a single logical change
- **Descriptive messages**: Follow `type(scope): description` format
- **Buildable order**: Commits should build on each other logically
- **No mixing concerns**: Don't combine unrelated changes (e.g., a bug fix and a new feature)

## Conventional Commits Format

Each commit message MUST follow this structure:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Common Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation
- `revert`: Reverts a previous commit
- `WIP`: Work in progress

**Scope:** The part of the codebase affected (optional but recommended).
**Description:** A brief, imperative-style description of the change.

## Workflow

### Step 0: Initialize and Discover Changes

1. **Check current git status**
   - Run `git status` to see current changes
   - Identify staged and unstaged changes
   - If no changes: inform user "No changes to commit. Please make changes first."

2. **Get list of changed files**
   - Use `git diff --name-only` for unstaged changes
   - Use `git diff --cached --name-only` for staged changes
   - Combine both if user wants to commit all changes

3. **Determine commit scope**
   - Use `ask_user_question` to ask:
     - "Should we commit all changes (staged + unstaged)?"
     - "Or only staged changes?"
     - "Or would you like to review unstaged changes first?"

### Step 1: Analyze File Changes

For each changed file, extract information to determine grouping:

1. **File path analysis**
   - Extract directory structure to determine scope
   - Example: `src/api/user.ts` → scope: `api/user` or `api`
   - Example: `tests/unit/user.test.ts` → scope: `tests` or `user-test`

2. **File extension analysis**
   - `.md` files → likely `docs` type
   - `.test.ts`, `.spec.ts` → likely `test` type
   - `.ts`, `.js`, `.py`, `.go` → likely `feat`, `fix`, or `refactor`
   - Configuration files (`package.json`, `.eslintrc`, etc.) → likely `chore`
   - Style files (`.css`, `.scss`, `.less`) → likely `style`

3. **Change content analysis** (when possible)
   - Use `git diff` to see actual changes
   - Look for keywords: "fix", "bug", "patch" → `fix`
   - Look for keywords: "feature", "new", "add" → `feat`
   - Look for keywords: "refactor", "cleanup", "restructure" → `refactor`
   - Look for keywords: "perf", "performance", "optimize" → `perf`
   - Look for test file changes → `test`
   - Look for documentation changes → `docs`

4. **Grouping strategy**
   - Group files by type first
   - Within each type, group by scope
   - Consider dependencies between changes
   - Ensure commits can be applied in order without breaking the build

### Step 2: Create Proposed Commit Groups

Based on the analysis, create proposed commit groups:

```
Proposed Commit Groups:

1. feat(api): add user authentication endpoints
   - src/api/auth.ts (new)
   - src/api/types.ts (modified)
   - src/middleware/auth.ts (new)

2. fix(validation): correct email validation regex
   - src/utils/validation.ts

3. docs(readme): update API documentation
   - README.md

4. test(auth): add authentication tests
   - tests/api/auth.test.ts

5. chore(deps): update package.json dependencies
   - package.json
   - package-lock.json
```

**Grouping Rules:**

1. **By Change Type**: Group all `feat` changes together (if they belong to the same feature), all `fix` changes together (if they fix the same issue), etc.

2. **By Scope**: Group changes that affect the same module/component together.
   - Example: All changes to `src/api/` can be grouped as scope `api`
   - Example: All changes to `src/components/Button/` can be grouped as scope `button`

3. **By Dependency**: If change A must be committed before change B for the codebase to build/work, they should be in separate commits with A first.

4. **By Logical Unit**: Changes that implement a single feature or fix should be in one commit.

5. **Separate Concerns**: Don't mix different types in one commit.
   - ❌ `feat & fix` in one commit
   - ✅ Separate `feat` and `fix` commits

### Step 3: Present and Validate with User

Present the proposed grouping to the user:

```
I've analyzed your changes and propose the following commit groups:

**Group 1: feat(api) - Add user authentication**
  Files: src/api/auth.ts, src/api/types.ts, src/middleware/auth.ts
  
**Group 2: fix(validation) - Correct email validation**
  Files: src/utils/validation.ts
  
**Group 3: docs - Update README with API docs**
  Files: README.md

Would you like to:
1. Accept this grouping and proceed with commits
2. Adjust the grouping (merge/split groups)
3. Rename any commit messages
4. See the actual changes in each group
```

Use `ask_user_question` with options:
- "Accept and commit"
- "Adjust grouping"
- "Rename messages"
- "Show changes"

### Step 4: Adjust Grouping (if requested)

If user selects "Adjust grouping":

1. Present current grouping as a list
2. Ask: "Which groups would you like to merge or split?"
3. Allow user to:
   - Merge two groups into one
   - Split a group into multiple groups
   - Move files between groups
   - Change commit type or scope

4. Re-display the updated grouping
5. Return to Step 3 for validation

### Step 5: Rename Messages (if requested)

If user selects "Rename messages":

1. Present each group with its current message
2. Ask for each group: "What would you like the commit message to be?"
3. Validate the new message follows Conventional Commits format
4. If invalid, explain the format and ask again

### Step 6: Show Changes (if requested)

If user selects "Show changes":

1. For each group, run `git diff` for the files in that group
2. Display the changes in a readable format
3. Ask if user wants to proceed with commits or make adjustments

### Step 7: Execute Commits

Once user approves the grouping:

1. **For each group in order:**
   - Stage the files in that group: `git add <file1> <file2> ...`
   - Commit with the message: `git commit -m "<type>(<scope>): <description>"`
   - Verify the commit was successful

2. **Handle errors:**
   - If a commit fails, stop and inform the user
   - Show the error message
   - Ask if they want to retry or investigate

3. **Final summary:**
   - Display all commits created
   - Show the final git log
   - Confirm with user: "All commits created successfully. Here's what was committed:"

### Step 8: Handle Edge Cases

**Case 1: No changes**
- Inform user: "No changes found. Please make changes first."
- Exit skill

**Case 2: Only one file changed**
- Propose a single commit with appropriate type and scope
- Ask user to confirm the commit message
- Execute the commit

**Case 3: Mixed staged and unstaged changes**
- Ask user: "You have both staged and unstaged changes. Should we commit:"
  - "Only staged changes"
  - "All changes (staged + unstaged)"
  - "Let me decide per file"

**Case 4: Merge conflicts or dirty working tree**
- Check `git status` for merge conflicts
- If conflicts exist: "You have merge conflicts. Please resolve them first."
- If working tree is dirty in a way that prevents commits, inform user

**Case 5: No git repository**
- Check if current directory is a git repo
- If not: "This is not a git repository. Please navigate to a git repository first."

**Case 6: Empty commit message**
- If no changes in a group after filtering: skip that group
- If user provides empty description: ask for a valid description

## Commit Message Generation

When generating commit messages automatically:

1. **Determine type:**
   - New files in `src/`: likely `feat`
   - Modified files with bug fix patterns: likely `fix`
   - Changes to test files: `test`
   - Changes to docs: `docs`
   - Changes to config files: `chore`
   - Refactoring without feature changes: `refactor`
   - Performance improvements: `perf`

2. **Determine scope:**
   - Extract from directory structure
   - For files in `src/api/`: scope = `api`
   - For files in `src/components/Button/`: scope = `button` or `components/button`
   - For files in `tests/`: scope = `tests` or more specific
   - If scope is too broad, use the common parent directory

3. **Generate description:**
   - Use the file names and changes to infer what was done
   - For new files: "add <file/functionality>"
   - For modified files: "update <file/functionality>"
   - For deleted files: "remove <file/functionality>"
   - Be concise but descriptive
   - Use imperative mood ("add" not "adds", "fix" not "fixes")

**Examples:**
- `src/api/user.ts` (new) + `src/api/user.test.ts` (new) → `feat(api): add user management endpoints`
- `src/utils/validation.ts` (modified) → `fix(validation): correct email regex pattern`
- `README.md` (modified) → `docs: update installation instructions`
- `.eslintrc.json` (modified) → `chore: update ESLint configuration`
- `package.json` + `yarn.lock` → `chore(deps): update dependencies`

## User Interaction Patterns

### Initial Prompt

When user invokes the skill without arguments:

```
"I'll help you create Conventional Commits from your changes. Let me analyze what you have."
```

Then discover and present the changes.

### With Argument

When user provides an argument like "fix login bug":

```
"I'll help you create commits for the 'fix login bug' changes. Let me analyze your current changes."
```

Use the argument as a prefix/hint for commit messages.

### Asking for Confirmation

Always ask for confirmation before executing commits:

```
"I will create the following commits:
1. feat(api): add user authentication
2. docs: update API documentation

Shall I proceed? (yes/no)"
```

## Implementation Guidelines

### File Analysis Using Bash

Use the provided helper script through `tools.file_system.bash`:

```bash
# Run the grouping script
tools.file_system.bash({
  command: './conventional-commits/scripts/group-changes.sh --all'
})
```

The script analyzes git changes and outputs grouping suggestions in text or JSON format.

For direct bash analysis without the script:

```bash
# Get all changed files (staged + unstaged + untracked)
git diff --name-only --diff-filter=d
git diff --cached --name-only --diff-filter=d
git ls-files --others --exclude-standard
```

### File Type Detection

Use file extensions to determine types:
- `.test.`, `.spec.` → `test`
- `.md` → `docs`
- `.json`, `.yaml`, `.yml`, `.toml`, `.rc`, `.config.js` → `chore`
- `.css`, `.scss`, `.less`, `.styl` → `style`
- Source files (`.ts`, `.js`, `.py`, `.go`, etc.) → `feat` (if new) or `fix` (if modified)

### Scope Extraction

Extract scope from directory structure:
- `src/api/...` → scope: `api`
- `src/components/...` → scope: `components`
- `tests/...` → scope: `tests`
- Use first directory as scope otherwise

### Grouping Approach

The grouping follows these rules:

1. **By Type**: Group files by commit type (feat, fix, docs, test, chore, etc.)
2. **By Scope**: Within each type, group by scope (directory or component)
3. **By Action**: New files → "add", deleted → "remove", modified → "update"
4. **Logical Order**: Commits should be ordered so the codebase builds at each step

Use the `group-changes.sh` script to automate this analysis.

## Best Practices

1. **Start with git status**: Always check the current git state first
2. **Be transparent**: Show the user what you're analyzing and why
3. **Default to safety**: When in doubt, create smaller commits rather than larger ones
4. **Respect user intent**: If the user provides context, use it to inform grouping
5. **Handle edge cases gracefully**: Always check for errors and inform the user
6. **Preserve order**: Commits should be ordered such that the codebase builds at each step

## Non-Goals

- Does not push commits to remote (user must do this manually)
- Does not force-push or rewrite history
- Does not create branches (operates on current branch)
- Does not resolve merge conflicts
- Does not make assumptions about the codebase structure

## Example Usage

**User:** "Please help me commit my changes using conventional commits."

**AI:**
1. Run `git status` to see changes
2. Find files: `src/api/user.ts`, `src/utils/validation.ts`, `README.md`
3. Analyze each file:
   - `src/api/user.ts`: new file, source code → `feat(api)`
   - `src/utils/validation.ts`: modified, has "fix" in diff → `fix(validation)`
   - `README.md`: modified → `docs`
4. Create proposed groups:
   - Group 1: `feat(api): add user management` - [user.ts]
   - Group 2: `fix(validation): correct email validation` - [validation.ts]
   - Group 3: `docs: update API documentation` - [README.md]
5. Present to user and ask for confirmation
6. Execute commits in order

## Finish

When commits are successfully created:

1. Display summary of all commits created
2. Show the git log with the new commits
3. Inform user: "All commits created successfully following Conventional Commits standard."
4. Suggest next steps:
   - "Would you like to push these commits?"
   - "Would you like to review the commits before pushing?"

If user cancels or errors occur:
- Inform user of the state
- Suggest how to recover or continue

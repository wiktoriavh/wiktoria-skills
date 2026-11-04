# conventional-commits Skill

A skill that automatically groups your changes into logical commits following the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) standard.

## What It Does

Instead of committing all your changes in one large commit, this skill:

1. **Analyzes** your staged and unstaged changes
2. **Groups** them by type (feat, fix, docs, etc.) and scope
3. **Creates** meaningful commit messages
4. **Executes** the commits in a logical order

## Usage

### Basic Usage

Just invoke the skill when you have changes to commit:

```
Use the conventional-commits skill
```

The skill will:
- Detect all your changed files
- Propose how to group them into commits
- Show you the proposed commit messages
- Ask for your approval
- Execute the commits

### With a Message Prefix

You can provide a prefix for the commit messages:

```
Use the conventional-commits skill with "WIP: "
```

This will prepend "WIP: " to all commit messages.

## How It Groups Changes

The skill uses intelligent grouping based on:

1. **File paths** - Files in the same directory are likely related
2. **File types** - Test files go together, docs files go together, etc.
3. **Change content** - Looks at the actual diff to understand what changed
4. **Conventional Commits types** - Groups by feat, fix, docs, chore, etc.

### Example Grouping

If you have these changes:
- `src/api/user.ts` (new feature)
- `src/api/types.ts` (supporting types)
- `src/utils/validation.ts` (bug fix)
- `README.md` (documentation update)
- `tests/api/user.test.ts` (new tests)

The skill will propose:

```
1. feat(api): add user management
   - src/api/user.ts
   - src/api/types.ts

2. fix(validation): correct email validation
   - src/utils/validation.ts

3. docs: update README with new API endpoints
   - README.md

4. test(api): add user tests
   - tests/api/user.test.ts
```

## Commit Message Format

All commits follow the Conventional Commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Common Types

| Type | When to Use |
|------|-------------|
| `feat` | New features |
| `fix` | Bug fixes |
| `docs` | Documentation changes |
| `style` | Formatting, missing semicolons, etc. |
| `refactor` | Code changes that don't fix bugs or add features |
| `perf` | Performance improvements |
| `test` | Adding or fixing tests |
| `chore` | Build process, dependencies, config files |
| `revert` | Reverting a previous commit |

## Customization

When the skill proposes groupings, you can:

1. **Accept** - Let it create the commits as proposed
2. **Adjust** - Merge or split groups, move files between groups
3. **Rename** - Edit the commit messages
4. **Review** - See the actual changes in each group before committing

## Requirements

- Must be run from within a git repository
- Git must be installed and available in PATH
- You must have changes to commit (staged or unstaged)

## What It Doesn't Do

- Does NOT push to remote (you must do this manually)
- Does NOT create branches
- Does NOT resolve merge conflicts
- Does NOT rewrite git history

## Tips

1. **Make small, focused changes** - The skill works best when each logical change is in its own set of files
2. **Use descriptive file names** - Helps the skill understand what the files do
3. **Write good commit messages in your code** - The skill reads diffs to understand changes
4. **Review before accepting** - Always check the proposed groupings make sense

## Example Session

```
User: Use the conventional-commits skill

AI: Analyzing your changes...
     
     I found 5 changed files:
     - src/api/user.ts (new)
     - src/api/types.ts (modified)
     - src/utils/validation.ts (modified)
     - README.md (modified)
     - tests/api/user.test.ts (new)
     
     I propose the following commits:
     
     Commit 1: feat(api): add user management
     - src/api/user.ts
     - src/api/types.ts
     
     Commit 2: fix(validation): correct email validation regex
     - src/utils/validation.ts
     
     Commit 3: docs: update README with API documentation
     - README.md
     
     Commit 4: test(api): add user management tests
     - tests/api/user.test.ts
     
     Would you like to:
     1. Accept and commit
     2. Adjust grouping
     3. Rename messages
     4. Show changes

User: Accept and commit

AI: Creating commits...
     [feat(api): add user management] ✓
     [fix(validation): correct email validation regex] ✓
     [docs: update README with API documentation] ✓
     [test(api): add user management tests] ✓
     
     All 4 commits created successfully!
```

## Installation

This skill is automatically available once placed in your skills directory. No additional installation needed.

## License

This skill is provided as-is. Use it responsibly.

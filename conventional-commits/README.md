# conventional-commits Skill

A skill that automatically groups your changes into logical commits following the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) standard.

## What It Does

Instead of committing all your changes in one large commit, this skill automatically:

1. **Analyzes** your staged and unstaged changes
2. **Groups** them by type (feat, fix, docs, etc.) and scope
3. **Creates** meaningful commit messages
4. **Executes** the commits in a logical order
5. **Provides** a summary of all created commits

## Usage

### Basic Usage

Just invoke the skill when you have changes to commit:

```
Use the conventional-commits skill
```

The skill will:
- Detect all your changed files
- Automatically group them into logical commits
- Create the commits without asking for confirmation
- Display a summary of all created commits

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

## Behavior

The skill operates automatically without requiring user confirmation:

- All changes (staged + unstaged) are committed
- Commits are created following the logical grouping rules
- A summary is displayed after all commits are created
- If errors occur, execution stops and you're informed

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

## Example Session

```
User: Use the conventional-commits skill

AI: Analyzing changes and creating commits...
     
     Found changes in 5 files:
     
     =========================================
     Commits created successfully!
     =========================================
     
     ✓ feat(api): add user management
       abc1234
         - src/api/user.ts
         - src/api/types.ts
     
     ✓ fix(validation): correct email validation regex
       def5678
         - src/utils/validation.ts
     
     ✓ docs: update README with API documentation
       ghi9012
         - README.md
     
     ✓ test(api): add user management tests
       jkl3456
         - tests/api/user.test.ts
     
     Total commits: 4
     
     Git log:
     jkl3456 test(api): add user management tests
     ghi9012 docs: update README with API documentation
     def5678 fix(validation): correct email validation regex
     abc1234 feat(api): add user management
```

## Installation

This skill is automatically available once placed in your skills directory. No additional installation needed.

## License

This skill is provided as-is. Use it responsibly.

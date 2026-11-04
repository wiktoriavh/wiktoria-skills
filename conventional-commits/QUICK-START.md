# conventional-commits - Quick Start

## One-Sentence Summary

Automatically groups your git changes into logical commits following the Conventional Commits standard.

## When to Use

- You have multiple file changes that should be separate commits
- You want to follow Conventional Commits but don't know how to group your changes
- You have changes across different parts of the codebase (features, fixes, docs, etc.)
- You want atomic, well-described commits

## Basic Usage

```
Use the conventional-commits skill
```

That's it! The skill will:
1. Analyze your staged and unstaged changes
2. Group them by type and scope
3. Propose commit messages
4. Ask for your approval
5. Create the commits

## Example

You've made changes to:
- `src/api/user.ts` (new feature)
- `src/utils/validation.ts` (bug fix)
- `README.md` (documentation update)

Run the skill, and it will propose:

```
Commit 1: feat(api): add user management
  - src/api/user.ts

Commit 2: fix(validation): correct email validation
  - src/utils/validation.ts

Commit 3: docs: update README
  - README.md
```

You can accept, adjust, or rename before committing.

## Key Features

✅ **Automatic grouping** - Intelligently groups files by type and scope
✅ **Conventional Commits compliant** - Follows the official standard
✅ **Interactive** - You review and approve all groupings
✅ **Flexible** - Works with staged, unstaged, or all changes
✅ **Safe** - Never pushes to remote, always asks for approval

## Pro Tips

1. **Start early** - Run the skill after each logical change, not at the end of a big session
2. **Review the groupings** - The skill is smart but you know your code best
3. **Use descriptive file names** - Helps the skill understand what your files do
4. **Write good code comments** - The skill reads diffs to understand changes

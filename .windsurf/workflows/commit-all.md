---
name: Commit All Changes
description: Adds all changes, generates a commit message, and performs a commit
---

# Commit All Changes Workflow

This workflow will:
1. Add all changes to the staging area
2. Generate a descriptive commit message based on the changes
3. Perform the commit

## Steps

```bash
# Get the current branch name
BRANCH_NAME=$(git branch --show-current)

# Add all changes
git add .

# Generate a commit message based on the changes
COMMIT_MSG="Auto-commit: Changes to $BRANCH_NAME branch"

# Get a summary of changes for the commit message detail
CHANGES=$(git diff --cached --name-status | awk '{print $2}' | sort | uniq | tr '\n' ', ' | sed 's/,$//')
if [ ! -z "$CHANGES" ]; then
  COMMIT_MSG="$COMMIT_MSG\n\nModified files: $CHANGES"
fi

# Commit the changes
git commit -m "$COMMIT_MSG"

# Show the commit
echo "✅ Successfully committed all changes to $BRANCH_NAME"
git show --name-status HEAD
```

## Usage

Run this workflow to quickly commit all changes in your repository with an automatically generated commit message.

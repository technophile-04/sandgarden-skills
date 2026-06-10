# Sandgarden Skills

A collection of agent skills for Claude Code and other AI coding assistants, following the [skills.sh](https://github.com/vercel-labs/skills) convention.

## Installation

Install skills using the skills CLI:

```bash
# Install all skills from this repository
npx skills add buidlguidl/sandgarden-skills

# Install a specific skill
npx skills add buidlguidl/sandgarden-skills --skills code-reviewer
```

## Available Skills

### code-reviewer

Review TypeScript, React, and Next.js code against high standards for clarity, simplicity, and maintainability. Provides brutally honest but supportive feedback following best practices.

**Use when:**

- Code has just been written or modified
- You want explicit code review
- Refactoring has been completed
- New features or components have been implemented

### pr-create

Create a GitHub PR with your changes. Analyzes commits, generates a descriptive title and summary, and creates the PR using the `gh` CLI.

**Use when:**

- You've completed changes and want to create a PR
- You want to submit your work for review
- You want to ship your changes

### se-2-challenges-branch-cleanup

Audit and prune stale branches in `scaffold-eth/se-2-challenges` (a branch-per-challenge repo with no shared main). Classifies every branch by PR state and last activity, proposes a delete list for human approval, and deletes safely with an SHA recovery file. Explains why git ancestry can't detect merged branches here.

**Use when:**

- The branch list has gotten cluttered with merged or abandoned branches
- You want to clean up / prune / delete old branches in `se-2-challenges`
- Periodic repo housekeeping

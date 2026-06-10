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

### pin-scaffold-ui-versions

Pin scaffold-ui (or any create-eth base-template dependency) to known-good versions across every SpeedRunEthereum challenge branch, opening one PR per challenge. Explains the create-eth `package.json` merge that makes the pin win, and bundles a script that sweeps all challenges.

**Use when:**

- A new scaffold-ui release breaks the challenge UIs
- Challenges look different after `npx create-eth`
- An upstream dependency bump needs to be held back across the `se-2-challenges` branches

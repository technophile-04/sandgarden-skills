# Sandgarden Skills

A collection of agent skills for Claude Code and other AI coding assistants, following the [skills.sh](https://github.com/vercel-labs/skills) convention.

## Installation

Install skills using the skills CLI:

```bash
# Install a specific skill
npx skills add sandgarden-skills/skills/code-reviewer

# Install from this repository
npx skills add github:sandgarden/sandgarden-skills
```

## Available Skills

### code-reviewer
Review TypeScript, React, and Next.js code against high standards for clarity, simplicity, and maintainability. Provides brutally honest but supportive feedback following best practices.

**Use when:**
- Code has just been written or modified
- You want explicit code review
- Refactoring has been completed
- New features or components have been implemented

### skill-creator
Guide for creating effective agent skills with specialized knowledge, workflows, or tool integrations.

**Use when:**
- Creating a new skill
- Updating an existing skill
- Learning skill best practices

## Development

Skills are organized in the `skills/` directory following the standard structure:

```
skills/
  skill-name/
    SKILL.md          # Skill definition with YAML frontmatter
    README.md         # Optional documentation
    scripts/          # Optional scripts
```

Each skill requires a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: skill-name
description: Brief description of what the skill does
---

# Skill Name

Detailed instructions...
```

## Structure

- `skills/` - Source directory for skill definitions
- `.claude/skills/` - Installed skills (gitignored, created by skills CLI)
- `.cursor/skills/` - Installed skills for Cursor (gitignored)
- Other agent directories follow the same pattern

Users install skills from the `skills/` directory into their agent-specific directories using `npx skills add`.

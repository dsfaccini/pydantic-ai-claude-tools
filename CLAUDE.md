# Pydantic AI Claude Tools

This is a **Claude Code configuration toolkit** for Pydantic AI contributors. It centralizes the AI coding workflow including worktree management, custom skills, commands, and agents.

## What this repo contains

- **Worktree scripts** (`scripts/`) - automate creating/removing git worktrees for feature branches
- **Claude Code skills** (`.claude/skills/`) - MRE bug workflow, pydantic-review, gh-cli helpers
- **Claude Code commands** (`.claude/commands/`) - handoff, check-pitfalls, ci-failures, fetch-pr-reviews
- **Claude Code agents** (`.claude/agents/`) - pr-review-sync
- **Template files** - `CLAUDE.local.template.md` and `CLAUDE.global.template.md` get copied to worktrees

## This is NOT a Pydantic AI worktree

The template files (`*.template.md`) contain instructions for working in actual Pydantic AI worktrees. They get copied to destination folders by the scripts. Don't confuse this repo with a Pydantic AI codebase.

## Usage

1. Run `./install.sh` to set up global CLAUDE.md symlink
2. Use `scripts/git-worktree-setup.sh` to create new feature branch worktrees
3. Use `scripts/git-worktree-checkout.sh` to check out existing PR branches
4. Templates and configs are automatically copied to new worktrees

## Writing Skills

Skills live in `.claude/skills/` and must follow this structure:

```
.claude/skills/<skill-name>/
├── SKILL.md          # Required - skill definition
└── <other-files>     # Optional - scripts, configs, etc.
```

### SKILL.md format

Every skill MUST have a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: <skill-name>
description: <when to use this skill - Claude uses this to decide relevance>
allowed-tools: Read, Grep, Glob, Bash(uv run:*)
---

# <Skill Title>

<skill content...>
```

- `description` - tells Claude when to apply the skill
- `allowed-tools` - optional comma-separated list of tools auto-approved for this skill (supports glob patterns like `Bash(cmd:*)`)

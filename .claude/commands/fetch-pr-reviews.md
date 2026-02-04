---
allowed-tools: Bash(.claude/skills/pr-feedback/fetch-latest.sh:*), Bash(mkdir:*), Bash(jq:*), Read, Write, Glob
description: Fetch latest PR feedback and save organized markdown to local-notes
---

# Fetch PR Feedback

Fetch latest PR feedback using the `pr-feedback` skill and save to local-notes.

## Usage

Arguments: `[PR_NUMBER] [DAYS_BACK]` (both optional, defaults to current branch's PR and 7 days)

## Steps

1. Run the fetch script:
   ```bash
   .claude/skills/pr-feedback/fetch-latest.sh $ARGUMENTS
   ```

2. Filter to external feedback only (exclude dsfaccini):
   ```bash
   .claude/skills/pr-feedback/fetch-latest.sh $ARGUMENTS | jq '{
     inline: [.pr_comments[] | select(.user != "dsfaccini")],
     general: [.issue_comments[] | select(.user != "dsfaccini")],
     reviews: [.reviews[] | select(.user != "dsfaccini")]
   }'
   ```

3. Save to `local-notes/pr-{number}-feedback-{YYYYMMDD}.md` with format:
   ```markdown
   # PR #{number} Feedback - {date}
   
   **Period:** {cutoff_date} to now
   **Inline comments:** {count}
   **General comments:** {count}
   **Reviews:** {count}
   
   ---
   
   ## Inline Comments by File
   
   ### {path} ({count})
   
   **L{line}** - {user} ({date})
   > {body}
   
   ---
   
   ## General Comments
   
   **{user}** ({date})
   > {body}
   
   ---
   
   ## Key Themes
   
   1. **Theme** - summary
   ```

4. Report: file saved, comment counts, files with most feedback. Update CLAUDE.local.md to reference the comments fetched. That way Claude Code can verify chnages against them.

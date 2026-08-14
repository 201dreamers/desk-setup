---
name: safety-guard
description: >-
  Guardrail for edits and destructive commands: investigate concrete facts before
  the first edit/write to a file, confirm before destructive Bash, and optionally
  install a hook that hard-blocks dangerous git. Use on production systems,
  autonomous/full-auto runs, migrations, deploys, data changes, when a wrong edit
  ripples across modules, or when the user wants git safety hooks / to block git
  push/reset.
---

# Safety Guard

Two behavioral gates I follow (rules for the agent, not tooling), plus an optional real hook for hard enforcement.

Self-eval doesn't work: ask "are you sure?" and answer is always "yes". Gathering concrete facts DOES work - the investigation itself changes the output. So gates demand facts, not confidence.

## Gate 1: investigate before edit

Before **first Edit/Write to a file** (each file in a MultiEdit batch counts), state these facts:

Edit existing file:
1. ALL files that import/require this file (Grep).
2. Public functions/classes the change affects.
3. If it reads/writes data files: field names, structure, date format (redacted/synthetic values, never raw prod data).
4. User's current instruction, quoted verbatim.

New file (Write):
1. File(s) + line(s) that will call this new file.
2. No existing file serves the same purpose (Glob).
3. Data-file schema if it reads/writes (redacted/synthetic).
4. User's current instruction, quoted verbatim.

Don't pre-answer to skip the gate - the investigation is the point. Data-schema check matters most: guessing ISO-8601 when real data is `%Y/%m/%d %H:%M` is a whole bug class.

## Gate 2: confirm before destructive Bash

Watched patterns:
```
rm -rf (esp. /, ~, project root)   git push --force        git reset --hard
git checkout . (discard all)       DROP TABLE / DROP DATABASE
docker system prune                kubectl delete           chmod 777
sudo rm                            npm publish              any --no-verify
```

On match, before running: (1) list files/data it modifies or deletes; (2) one-line rollback procedure; (3) user's current instruction verbatim. Show what it does, ask confirmation, suggest safer alternative.

Routine (non-destructive) Bash: gate once per session - state the current request in one sentence + what the command verifies/produces. Don't gate every command; destructive gates every time.

## Scope restriction (optional)

When user wants edits confined to one area: only Write/Edit inside the named dir (e.g. `src/api/`); read anything; block writes elsewhere with an explanation. Max safety for autonomous runs = confine writes + confirm destructive everywhere.

## Enforce at hook level (optional)

Gates 1-2 rely on me following them. For hard enforcement, install a PreToolUse hook that blocks dangerous git before it runs. Bundled: `scripts/block-dangerous-git.sh` (reads tool JSON on stdin, exit 2 = block). Blocks `git push` (all variants incl. `--force`), `git reset --hard`, `git clean -f`/`-fd`, `git branch -D`, `git checkout .`/`git restore .`.

Setup:
1. Ask scope: this project (`.claude/`) or all projects (`~/.claude/`).
2. Copy script to `<scope>/hooks/block-dangerous-git.sh`; `chmod +x`.
3. Add to `<scope>/settings.json` - merge into existing `hooks.PreToolUse`, don't overwrite:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "~/.claude/hooks/block-dangerous-git.sh" } ] }
    ]
  }
}
```
Project scope instead: `"$CLAUDE_PROJECT_DIR"/.claude/hooks/block-dangerous-git.sh`.

4. Ask if user wants to add/remove patterns; edit the script's `DANGEROUS_PATTERNS`.
5. Verify: `echo '{"tool_input":{"command":"git push origin main"}}' | <path>` -> exit 2 + BLOCKED on stderr.

**Caveat:** default list blocks ALL `git push`, not just force. Tighten `DANGEROUS_PATTERNS` before enabling if you push normally.

## Related

- `plan-requirements` - scope/AC before building (this guards the editing itself).
- `ascii-text` - ASCII rule. Post-edit review: `gh-pr-review`, `/code-review`.

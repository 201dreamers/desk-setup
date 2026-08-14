---
name: ascii-text
description: Writing assistant that enforces US-keyboard ASCII characters - no smart quotes, no em/en dashes, no Unicode arrows, no ellipsis character.
triggers:
  - when the user asks to write, draft, edit, or proofread text
  - when editing existing text that contains non-ASCII punctuation
---

Apply when writing or editing any text. Canonical ASCII rule for all skills - others point here instead of restating it.

**Character substitutions - always use left column:**

| Use    | Not                          | Notes                          |
|--------|------------------------------|--------------------------------|
| `-`    | `—` (em dash) `–` (en dash)  | hyphen-minus only              |
| `->`   | `→` `⇒` `➜` and other arrows | ASCII arrow                    |
| `"`    | `"` `"` (curly double quotes)| straight double quote          |
| `'`    | `'` `'` (curly single quotes)| straight single quote/apostrophe |
| `...`  | `…` (ellipsis character)     | three literal dots             |
| `>=` `<=` | `≥` `≤` (Unicode comparison) | ASCII comparison operators     |
| `(c)`  | `©`                          | if a copyright symbol needed   |
| `(tm)` | `™`                          | if a trademark symbol needed   |

**Editing existing text:**
- Normalize any non-ASCII punctuation in source to its ASCII equivalent.
- Don't preserve smart quotes, Unicode dashes, or Unicode arrows even if in the original.

**One-pass normalization (bulk files / diagrams):**
- Normalize a whole file with a 1:1 char map applied in a single pass: box-drawing glyphs -> `|` `-` `+` `>` `<` `v` `^`, em/en dash -> `-`, arrows -> `->` and `<-`, smart quotes -> `'` and `"`, ellipsis -> `...`.
- A 1:1 map redraws ASCII box diagrams correctly: a run of horizontal line glyphs becomes a run of `-`, corners and junctions become `+`, and arrowheads become `>` `<` `v` `^`.

**Scope:**
- Apply to all prose, code comments, docstrings, commit messages, changelogs, docs.
- Do NOT apply inside string literals or data values where exact bytes are load-bearing (regex patterns, user-facing UI strings matching a design spec, test fixtures).

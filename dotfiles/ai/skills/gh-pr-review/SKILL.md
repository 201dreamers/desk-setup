---
name: gh-pr-review
description: >
  Local, read-only PR review. Read the PR, analyze the diff and CI, present
  structured findings in the terminal. Use when reviewing a PR or re-reviewing
  after fixes. Never posts comments, reviews, or approvals to GitHub - output
  stays local.
---

# GitHub PR Review Workflow (local, read-only)

Review a PR and present findings in the terminal. **This skill never writes to GitHub** - no comments, no reviews, no approvals, no status changes. Reads only. If the user wants feedback on the PR itself, hand them the text to paste; do not post it.

## Step 1: Gather context (reads only)

Run in parallel - but **isolate `gh pr checks` in its own batch**: it exits non-zero when any check failed, and non-zero exit cancels the other parallel calls in the batch (you lose the reviews/comments fetches, must re-run).

```bash
# Batch A (safe to parallelize):
gh pr view <number> --json isDraft,state,title,author,baseRefName,headRefName,body
gh pr diff <number>
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# Batch B (run separately - non-zero exit on any failing check is expected):
gh pr checks <number>
```

All of the above are GET/read requests. Reviews/comments fetches are **important** - they let you account for prior feedback instead of repeating it.

Read the **full changed files** (not just diff) for surrounding context - base class methods, fixture chains, helpers. Test PRs in this repo: trace fixture deps through `conftest.py` + `tests/plugins/` for setup/teardown behavior.

## Step 2: Investigate CI checks (reads only)

Don't just report pass/fail. For any failing check:

1. Job details (finds failing step): `gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs`
2. Failing job logs for root cause: `gh api repos/{owner}/{repo}/actions/jobs/{job_id}/logs 2>&1 | tail -100` - logs endpoint returns plain text not JSON; tail keeps error in context. Widen `tail` if failure buried deeper.
3. Distinguish **code issues** (lint/test failures) from **infra issues** (billing, runner, flaky infra) - flag only code failures as blocking. Lint failure: name offending files + suggest fix command (e.g. `make format && make lint`).

## Step 3: Analyze, structure feedback

1. **Numbered issues** - blocking, with file:line refs + code snippets
2. **Minor observations** - non-blocking nits
3. **What looks good** - positive aspects

Account for existing comments: prior reviewer flagged + author fixed -> don't re-raise; prior comment unresolved -> note it; note which prior feedback the latest push addressed.

**Scope: stay inside the PR diff.** Don't hunt drift in untouched files; never raise drift in local/gitignored files (`CLAUDE.md`, `.gitignore` entries, `.claude/`) - not shared with the team, not the author's responsibility. Spot something in a local file worth fixing -> do it yourself outside the review.

## Step 4: Present to user in the terminal

Check PR state first: `gh pr view <number> --json isDraft,state`, and note draft state at the top if it is a draft.

Present the review in the terminal:
- Structured feedback (issues, nits, positives)
- CI status + root cause for any failures
- A suggested verdict for the user's own judgment (Approve / Request changes / Approve with questions) - as advice, not an action

**Stop here.** Do not post to GitHub, do not approve, do not request changes. The user takes it from here on GitHub themselves. If they ask you to post, restate that this skill is local-only and offer the formatted text to copy.

## Step 5: Re-review after fixes (reads only)

1. Fetch **latest diff** (`gh pr diff`) + **all comments** (inline + review-level, via `gh api` GET)
2. Compare vs prior feedback - build a resolution table:

| Prior Feedback | Status |
|----------------|--------|
| Issue from reviewer X | Fixed / Still open / Partially addressed |

3. Check **new issues** in the latest push
4. Re-check CI (new push may trigger new runs)
5. Present the re-review summary + resolution table in the terminal

## Notes

- Every `gh` call here is a read (GET). Do not use `--method POST/PATCH/PUT/DELETE`, `gh pr review`, `gh pr comment`, `gh pr merge`, or `gh api ... /reviews` POST - those write to GitHub and are out of scope for this skill.
- `--repo` may be needed for GHE reads: `--repo name`. `gh api` paths use `repos/{owner}/{repo}/...` regardless.
- `gh pr checks` exits non-zero on any failing check - keep out of parallel batches with commands whose output you need.
